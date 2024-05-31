# configuration-r

### wglb wgl@ciex-security.com

This is a project to do find recursively configuration values
in config files. If the config item is not found, the configuration 
file of the same name in the parent directory is searched. This
continues until the value is located, or the root directory 
is encountered.

### Example of use


```common-lisp
(defun worker()
  (let ((val (get-config "config-file-name.lsp" :workload)))
	(format t "value is ~s~%" val)))

----- config-file-name.lsp ----

((:workload . 9)
 (:output-file . "result.out"))
```


Configuration files are s-expressions, a list of cons elements whose `car` is the parameter name
and the `cdr` is the value.

### get-config

```common-lisp
getconfig (config-file-name property config-file-directory debug)
```

If debug is not nil, traces of the search.

### Required files

`xlog` is required. It can be found at [xlog](https://github.com/wglb/xlog/tree/master).




