;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)) )

(in-package #:configuration-r)

(defun find-file-in-parent0 (pn target &optional (visited-dirs '()))
  "Helper for FIND-FILE-IN-PARENT. Recursively searches for TARGET starting from PN and going up,
   keeping a list of visited directories to prevent infinite loops."
  (break "find-file-in-parent0: pn ~s target ~s visited ~s done? ~s"
		 pn
		 target
		 visited-dirs
		 (or (null pn) (equal (namestring pn) (namestring #P"/")) (equal (namestring pn) (namestring #P"")) (member pn visited-dirs :test #'uiop:pathname-equal)))
  (break "pnd ~s pnd of P'/' ~s and pnd of P'' ~s"  (pathname-directory pn) (pathname-directory #P"") (pathname-directory #P"/"))
  (when (or (null pn) (equal (namestring pn) (namestring #P"/")) (equal (namestring pn) (namestring #P"")) (member pn visited-dirs :test #'uiop:pathname-equal))
    (debugc 5 (xlogntf "ffip0: Circular path detected or end of path reached, stopping recursion."))
	(break "ffip0: Circular path detected or end of path reached, stopping recursion.")
    (return-from find-file-in-parent0 nil))
  
  (let ((tpn (merge-pathnames target pn)))
    (debugc 5 (xlogntf "ffip0: target ~s pn ~s -> tpn ~s" target pn tpn))
	(break "ffip0: target ~s pn ~s -> tpn ~s" target pn tpn)
    (if (probe-file tpn)
        tpn
        (let ((npn (pathname-parent-directory-pathname pn)))
          (break "tpn ~s does not exist, pn is ~s path-parent-dir ~s" tpn pn npn)
          (find-file-in-parent0 npn target (cons pn visited-dirs))))))

(defun find-file-in-parent (pn target)
  "Searches for TARGET file in PN and its parent directories.
   Returns the pathname of the found file or NIL."
  (let* ((initial-pn (ensure-directory-pathname pn))
         (ans (find-file-in-parent0 initial-pn target)))
	(break "find-file-in-parent: pn ~s target ~s" pn target)
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
          (if debug (xlogntft "read-config-file: read ~s" data))
          data))
    (error (e)
      (if debug (xlogntft "read-config-file: Error reading ~a: ~a" filename e))
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
	(break "get-config: filename ~s property ~s dir ~s debug ~s" filename property dir debug)
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
                (if debug (xlogntft "gc: Did not find file ~a searching from ~a" target-file initial-dir-pathname))
                nil)))
        (progn
          (if debug (xlogntft "gc: Cannot search for file with no name/type: ~a" filename))
          nil))))

(defun get-config1 (filename property &key (debug nil))
  "This function gets a property from a specific file path.
   It searches up from the directory of the given FILENAME."
  (let* ((file-pathname (ensure-pathname filename :want-pathname t))
         (dir-pathname (pathname-directory-pathname file-pathname))
         (fn (pathname-name file-pathname))
         (ty (pathname-type file-pathname)))
	(break "get-config1 filename ~s property ~s debug ~s" filename property debug)
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
