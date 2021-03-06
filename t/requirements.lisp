(in-package :cl-user)
(defpackage ningle-test.requirements
  (:use :cl
        :ningle
        :cl-test-more)
  (:import-from :clack.test
                :test-app
                :*clack-test-port*)
  (:import-from :drakma
                :http-request))
(in-package :ningle-test.requirements)

(plan 11)

(defvar *app*)
(setf *app* (make-instance '<app>))

(setf (route *app* "/" :accept '("text/html" "text/xml"))
      (lambda (params)
        (declare (ignore params))
        "<html><body>Hello, World!</body></html>"))

(setf (route *app* "/" :accept "text/plain")
      (lambda (params)
        (declare (ignore params))
        "Hello, World!"))

(ok (not (route *app* "/")))
(ok (route *app* "/" :accept "text/plain"))

(flet ((localhost (path)
         (format nil "http://localhost:~D~A" clack.test:*clack-test-port* path)))
  (clack.test:test-app
   *app*
   (lambda ()
     (multiple-value-bind (body status)
         (drakma:http-request (localhost "/")
                              :accept "text/plain")
       (is body "Hello, World!")
       (is status 200))

     (multiple-value-bind (body status)
         (drakma:http-request (localhost "/")
                              :accept "text/html")
       (is body "<html><body>Hello, World!</body></html>")
       (is status 200))
     (is (nth-value 1
                    (drakma:http-request (localhost "/")
                                         :accept "application/json"))
         404))))

(is-error
 (setf (route *app* "/" :user-agent "Songbird/(\\d+\\.\\d+\\.\\d+)")
       (lambda (params)
         (format nil "Songbird ver ~A" (aref (cdr (assoc :user-agent params)) 0))))
 'simple-error)

(setf (requirement *app* :user-agent)
      (lambda (user-agent-regexp)
        (ppcre:scan-to-strings user-agent-regexp (clack.request:user-agent *request*))))

(setf (route *app* "/" :user-agent "Songbird/(\\d+\\.\\d+\\.\\d+)")
      (lambda (params)
        (format nil "Songbird ver ~A" (aref (cdr (assoc :user-agent params)) 0))))

(flet ((localhost (path)
         (format nil "http://localhost:~D~A" clack.test:*clack-test-port* path)))
  (clack.test:test-app
   *app*
   (lambda ()
     (is (nth-value 1
                    (drakma:http-request (localhost "/")))
         404)
     (multiple-value-bind (body status)
         (drakma:http-request (localhost "/")
                              :user-agent "Songbird/2.2.0")
       (is status 200)
       (is body "Songbird ver 2.2.0")))))

(finalize)
