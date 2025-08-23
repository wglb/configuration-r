;;;; configuration-r.lisp

(in-package #:configuration-r)

(defun read-config-file (file-path &key (debug nil))
  "Reads a Lisp configuration file at FILE-PATH and returns an alist.
   Returns NIL if the file does not exist or cannot be read."
  (if (probe-file file-path)
      (handler-case
          (with-open-file (stream file-path :direction :input)
            (let ((content (read stream)))
              (if debug (xlogntf "rcf: Read content from file ~s" file-path))
              content))
        (error (e)
          (if debug (xlogntf "rcf: Error reading file ~s: ~a" file-path e))
          nil))
      (progn
        (if debug (xlogntf "rcf: File not found at ~s" file-path))
        nil)))


(defun get-config (filename property &key (dir (uiop:getcwd)) (debug nil))
  "This function gets a PROPERTY from a configuration file named FILENAME.
   It signals an error if FILENAME contains a directory path."
  (let ((fn-pathname (uiop:ensure-pathname filename :want-pathname t)))
    (if (pathname-directory fn-pathname)
        (error "The filename argument '~a' should not contain a directory path." filename)))
  (let* ((dir-pathname (uiop:ensure-directory-pathname dir)))
    (loop for current-dir = dir-pathname then (uiop:pathname-parent-directory-pathname current-dir)
          while (and current-dir (not (equal #P"/" current-dir)))
          do
             (let ((config-file (merge-pathnames filename current-dir)))
               (when (uiop:probe-file* config-file)
                 (let ((alist (read-config-file config-file :debug debug)))
                   (when alist
                     (let ((ans (cdr (assoc property alist))))
                       (if debug (xlogntf "gc: prop ans ~s val ~s from file ~s" property ans config-file))
                       (return-from get-config (values ans config-file)))))))
          finally
             (if debug (xlogntf "gc: Did not find file ~a searching from ~a" filename dir-pathname))
             (return-from get-config nil))))

(defun get-config1 (filename property &key (debug nil))
  "This function gets a property from a specific file path.
   It searches up from the directory of the given FILENAME."
  (let* ((file-pathname (uiop:ensure-pathname filename :want-pathname t))
         (dir-pathname (uiop:pathname-directory-pathname file-pathname))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname)))
    (if (and fn ty)
        (loop for current-dir = dir-pathname then (uiop:pathname-parent-directory-pathname current-dir)
              while (and current-dir (not (equal #P"/" current-dir)))
              do
                 (let ((config-file (merge-pathnames (file-namestring file-pathname) current-dir)))
                   (when (uiop:probe-file* config-file)
                     (let ((alist (read-config-file config-file :debug debug)))
                       (when alist
                         (let ((ans (cdr (assoc property alist))))
                           (if ans
                               (progn
                                 (if debug (xlogntf "gc1: prop ans ~s val ~s from file ~s" property ans config-file))
                                 (return-from get-config1 (values ans config-file)))
                               (if debug (xlogntf "gc1: Did not find property ~s in file ~s" property config-file))))))))
        (progn
          (if debug (xlogntf "gc1: Cannot search for file with no name/type: ~a" filename))
          nil)))))

