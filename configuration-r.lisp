;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)))

(in-package #:configuration-r)

(defun find-file-with-property-in-parent0 (pn target property)
  "Helper for FIND-FILE-WITH-PROPERTY-IN-PARENT. Recursively searches for TARGET starting from PN and going up, checking for PROPERTY."
  (let ((file-found (probe-file (merge-pathnames target pn))))
    (cond
      ((and file-found
            (let ((alist (read-config-file file-found)))
              (when (and alist (listp alist))
                (assoc property alist))))
       file-found)
      ((equal (pathname-directory pn) '(:absolute))
       (debugc 5 (xlogntf "ffip0: Reached root directory. Search terminating."))
       nil)
      (t
       (let ((npn (pathname-parent-directory-pathname pn)))
         (debugc 5 (xlogntf "ffip0: File not found or property missing in ~s. Trying parent ~s" pn npn))
         (find-file-with-property-in-parent0 npn target property))))))

(defun find-file-with-property-in-parent (pn target property)
  "Searches for TARGET file in PN and its parent directories.
   Returns the pathname of the found file or NIL."
  (let* ((initial-pn (ensure-directory-pathname pn))
         (ans (find-file-with-property-in-parent0 initial-pn target property)))
    ans))

(defun read-config-file (filename &key (debug nil))
  "Reads a config file and returns its content as an alist.
   Returns NIL if the file doesn't exist or an error occurs."
  (cond
    ((not filename)
     (if debug (xlogntf "read-config-file: Filename is NIL, returning NIL."))
     nil)
    (t
     (debugc 5 (xlogntf "read-config-file: reading ~s" filename))
     (handler-case
         (with-open-file (stream filename :direction :input)
           (cond
             ((listen stream)
              (let ((data (read stream)))
                (if debug (xlogntf "read-config-file: read ~s" data))
                data))
             (t
              (if debug (xlogntf "read-config-file: file ~s is empty." filename))
              nil)))
       (error (e)
         (if debug (xlogntf "read-config-file: Error reading ~a: ~a" filename e))
         nil)))))

(defun get-config (filename property &key (dir nil) (debug nil))
  "Gets a property from a configuration file named FILENAME.
   Searches up from the directory DIR (or current directory if DIR is nil).
   Returns values of (result filename)."
  (cond
    ((pathname-directory filename)
     (error "Filename must not contain a directory component."))
    (t
     (let* ((initial-dir-pathname
			  (merge-pathnames (if dir
                                   (ensure-directory-pathname dir)
                                   (getcwd))))
            (fn (pathname-name filename))
            (ty (pathname-type filename)))
       (cond
         ((and fn ty)
          (let* ((target-file (make-pathname :name fn :type ty))
                 (config-file (find-file-with-property-in-parent initial-dir-pathname target-file property)))
            (cond
              (config-file
               (let ((alist (read-config-file config-file :debug debug)))
                 (when (and alist (listp alist))
                   (let ((ans (cdr (assoc property alist))))
                     (if debug (xlogntf "gc: prop ans ~s val ~s from file ~s" property ans config-file))
                     (values ans config-file)))))
              (t
               (if debug
                   (xlogntft "gc: Did not find file ~a searching from ~a" target-file initial-dir-pathname))
               nil))))
         (t
          (if debug
              (xlogntft "gc: Cannot search for file with no name/type: ~a" filename))
          nil))))))

(defun get-config1 (filename property &key (debug nil))
  "This function gets a property from a specific file path.
   It searches up from the directory of the given FILENAME."
  (let* ((file-pathname (merge-pathnames (ensure-pathname filename :want-pathname t)))
         (dir-pathname (pathname-directory-pathname file-pathname))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname)))
    (cond
      ((and fn ty)
       (let* ((target-file (make-pathname :name fn :type ty))
              (config-file (find-file-with-property-in-parent dir-pathname target-file property)))
         (cond
           (config-file
            (let ((alist (read-config-file config-file :debug debug)))
              (when (and alist (listp alist))
                (let ((ans (cdr (assoc property alist))))
                  (if debug (xlogntft "gc1: prop ans ~s val ~s from file ~s" property ans config-file))
                  (values ans config-file)))))
           (t
            (if debug
                (xlogntft "gc1: Did not find file ~a searching from ~a" target-file dir-pathname))
            nil))))
      (t
       (if debug
           (xlogntft "gc1: Cannot search for file with no name/type: ~a" filename))
       nil))))
