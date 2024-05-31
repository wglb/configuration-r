;;;; configuration-r.lisp

(declaim (optimize (speed 0) (safety 3) (space 0) (debug 3)) )

(in-package #:configuration-r)

(defun find-file-in-parent0 (pn target)
  (if pn
      (let ((tpn (merge-pathnames target pn)))
        (debugc 5 (xlogntf "ffip: target ~s pn ~s" target pn))
        (if (probe-file tpn)
            tpn
            (let ((npn (truename (uiop:pathname-parent-directory-pathname pn))))
              (if (equal npn pn)
                  nil
                  (find-file-in-parent0 npn target)))))))

(defun find-file-in-parent (pn target)
  "Account for being in an emacs volume that won't cd .. to root of file system"
  (let ((ans (find-file-in-parent0 pn target)))
	(debugc 5 (xlogntf "probe says ~a" ans))
	(unless ans
	  (xlogntf "gotta null")
	  (setf ans (find-file-in-parent0  "~/." target))
	  (debugc 5 (xlogntf "Now got ans ~a" ans)))
	ans))

(defparameter *config* -1)

(defun get-config0 (dir fn ty property &key (debug nil) )
  "look in parent, recursiveley. If a mounted /Volume on mac os-x, it won't go to home directory. "
  (if debug
	  (xlogntf "gc0: dir ~s fn ~s ty ~s prop ~s" dir fn ty property))
  (if dir
	  (let*  ((fnx (make-pathname :directory dir :name fn :type ty))
			  (*print-pretty* nil)
			  (dfnx (pathname-directory fnx))
			  (pf (probe-file fnx)))
		(if debug (xlogntf "gc0: pf is ~s fnx is ~s dfnx is ~s" pf fnx dfnx))
		(if pf
			(with-open-file (fi pf :direction :input)
			  (let* ((result (read fi))
					 (ans (assoc property result)))
				(if debug
					(xlogntf "gc0: config file ~s ~%    assoc ~s ~%    pf ~s" result ans pf))
				(if (not ans)
					(get-config0 (butlast dir) fn ty  property)
					(let ((res (cdr ans)))
					  (if debug
						  (xlogntf "gc0:prop ~s val ~s dir ~s" property res dfnx))
					  res))))
			(get-config0 (butlast dfnx) fn ty property)))
	  nil))

(defun get-config (filename property &key  (dir nil) (debug nil))
  "get-config answers the property found in the file named 'fn'. 
   filename should be filename alone with no directory components
   If fn is not in the specified directory, or if the property is not found in that file, get-config will look in the parent.
    Recursively."
  (let* ((ddir (if dir
				   (pathname-directory dir)
				   (pathname-directory *default-pathname-defaults*)))
		 
		 (fn (pathname-name filename))
		 (ty (pathname-type filename)))
	(if debug
		(xlogntf "gc: fn ~s prop ~s dir ~s" filename property dir))
	
	(handler-case
		(get-config0 ddir fn ty property :debug debug)
	  (error (e)
		(break "handler-case get-config filename ~a property ~s dir ~s fn ~s ty ~s" filename property ddir fn ty)
		(xlogntf "get-config: error ~e in getting ~a from ~a" e property filename)))))




