;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)) )

(in-package #:configuration-r)

(defun find-file-in-parent0 (pn target)
  "Helper for FIND-FILE-IN-PARENT. Recursively searches for TARGET starting from PN and going up."
  #+nil (break "ffip: pn ~s target ~s root? ~s" pn target (equal #P"/" pn))
  (if (and (not (equal #P"/" pn)) (not (equal #P"" pn)))
      (let ((tpn (merge-pathnames target pn)))
        (debugc 5 (xlogntf "ffip0: target ~s pn ~s -> tpn ~s" target pn tpn))
        (if (probe-file tpn)
            tpn
            (let ((npn (pathname-parent-directory-pathname pn)))
              (debugc 5 (xlogntf "ffip0: no file in ~s, trying parent ~s" pn npn))
              ;; The fix: Check if the new path is NIL or the directory list is a proper list (not circular).
              (if (or (null npn) (not (listp (pathname-directory npn))))
                  nil
				  (if (equal #P"/" tpn)
					  nil
					  (find-file-in-parent0 npn target))))))
	  (progn #+nil (break "ffip bogon: pn ~s target ~s root? ~s" pn target (equal #P"/" pn))
			 nil)))


(defun find-file-in-parent (pn target)
  "Searches for TARGET file in PN and its parent directories.
   Returns the pathname of the found file or NIL."
  (let* ((initial-pn (ensure-directory-pathname pn))
         (ans (find-file-in-parent0 initial-pn target)))
	(unless ans
	  (xlogntf "ffip: didn't find in current path, trying home directory fallback.")
	  ;; Fallback to user's home directory if not found in current path
	  (setf ans (find-file-in-parent0 (user-homedir-pathname) target))
	  (debugc 5 (xlogntf "ffip: Now got ans ~a after home fallback" ans)))
	ans))

(defun read-config-file (filename &key (debug nil))
  "Reads a config file and returns its content as an alist.
   Returns NIL if the file doesn't exist or an error occurs."
  (debugc 5 (xlogntf "read-config-file: reading ~s" filename))
  (handler-case
      (with-open-file (stream filename :direction :input)
        (let ((data (read stream)))
          (if debug (xlogntf "read-config-file: read ~s" data))
          data))
    (error (e)
      (if debug (xlogntf "read-config-file: Error reading ~a: ~a" filename e))
      nil)))

(defun get-config (filename property &key (dir nil) (debug nil))
  "Gets a property from a configuration file named FILENAME.
   Searches up from the directory DIR (or current directory if DIR is nil).
    Returns values of (result filename)."
  (let* ((initial-dir-pathname (cond
                                 (dir (ensure-directory-pathname dir))
                                 (t (getcwd))))
         (fn (pathname-name filename))
         (ty (pathname-type filename)))
    (if (and fn ty)
        (let* ((target-file (make-pathname :name fn :type ty))
               (config-file (find-file-in-parent initial-dir-pathname target-file)))
          (if config-file
              (let ((alist (read-config-file config-file :debug debug)))
                (when alist
                  (let ((ans (cdr (assoc property alist))))
                    (if debug (xlogntf "gc: prop ans ~s val ~s from file ~s" property ans config-file))
                    (values ans config-file))))
              (progn
                (if debug (xlogntf "gc: Did not find file ~a searching from ~a" target-file initial-dir-pathname))
                nil)))
        (progn
          (if debug (xlogntf "gc: Cannot search for file with no name/type: ~a" filename))
          nil))))

(defun get-config1 (filename property &key (debug nil))
  "This function gets a property from a specific file path.
   It searches up from the directory of the given FILENAME."
  (let* ((file-pathname (ensure-pathname filename :want-pathname t))
         (dir-pathname (pathname-directory-pathname file-pathname))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname)))
    (if (and fn ty)
        (let* ((target-file (make-pathname :name fn :type ty))
               (config-file (find-file-in-parent dir-pathname target-file)))
          (if config-file
              (let ((alist (read-config-file config-file :debug debug)))
                (when alist
                  (let ((ans (cdr (assoc property alist))))
                    (if debug (xlogntf "gc1: prop ans ~s val ~s from file ~s" property ans config-file))
                    (values ans config-file))))
              (progn
                (if debug (xlogntf "gc1: Did not find file ~a searching from ~a" target-file dir-pathname))
                nil)))
        (progn
          (if debug (xlogntf "gc1: Cannot search for file with no name/type: ~a" filename))
          nil))))
