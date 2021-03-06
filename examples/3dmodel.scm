;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This little 3D object viewer relies on the
;; assimp-lib.scm file. You'll need to load that first
;;
;; Also, there are a few hard paths that in this file
;; that you'll need to change to something suitable
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; change working directory
(llvm:compile "declare i32 @chdir(i8*)")

(definec change-working-dir
  (lambda (path)
    (chdir path)))

(define libglu (sys:open-dylib "libGLU.so"))
(bind-lib libglu gluLookAt [double,double,double,double,double,double,double,double,double]*)
(bind-lib libglu gluPerspective [double,double,double,double]*)
(bind-lib libglu gluErrorString [i8*,i32]*)


(definec setup
  (lambda ()
    (glEnable GL_LIGHTING)
    (glEnable GL_LIGHT0)
    (let ((diffuse1 (heap-alloc 4 float))
	  (specular (heap-alloc 4 float))
	  (position1 (heap-alloc 4 float)))
      (aset! diffuse1 0 0.7) (aset! diffuse1 1 0.7) (aset! diffuse1 2 0.7) (aset! diffuse1 3 1.0)      
      (aset! specular 0 0.0) (aset! specular 2 0.0) (aset! specular 3 0.0) (aset! specular 4 1.0)
      (aset! position1 0 10.0) (aset! position1 1 10.0) (aset! position1 2 10.0) (aset! position1 3 0.0)

      (glLightfv GL_LIGHT0 GL_DIFFUSE diffuse1)
      (glLightfv GL_LIGHT0 GL_SPECULAR specular)
      (glLightfv GL_LIGHT0 GL_POSITION position1)

    (glShadeModel GL_SMOOTH)
    (glEnable GL_COLOR_MATERIAL)
    (glColorMaterial 1028 GL_DIFFUSE)    
    (glEnable GL_DEPTH_TEST))))


(definec gl-init
  (lambda (w h)
    (setup)
    (glViewport 0 0 w h)
    (glMatrixMode 5889)
    (glLoadIdentity)
    (gluPerspective 25.0 (/ (i32tod w) (i32tod h)) 0.001 10.0)
    (glMatrixMode 5888)
    (glEnable GL_NORMALIZE)
    (glEnable 2929)
    1)))
	      
(definec look-at
  (lambda (eyex eyey eyez centre-x centre-y centre-z up-x up-y up-z)
    (glLoadIdentity)
    (gluLookAt eyex eyey eyez centre-x centre-y centre-z up-x up-y up-z)))


;; a trivial opengl draw loop
;; need to call glfwSwapBuffers to flush
(definec gl-callback
  (lambda (model display-list angle:double)
    (glClearColor 0.05 0.05 0.05 1.0)
    (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))
    (glLoadIdentity)
    
    (gluLookAt (* 2.0 (cos angle))
	       (* 0.5 (cos angle))
	       (* 2.0 (sin angle))
	       0.0 0.0 0.0
	       0.0 1.0 0.0)

    ;; you might need this rotatation depending on the model
    ;(glRotated -90. 1.0 0.0 0.0)    
    (draw-model model display-list)
    (glfwSwapBuffers)
    1))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NOW START OPENGL AND LOAD THE MODEL

;; first initalize opengl
;; (we'll need it before we build a display list)

;; code to open a window
(definec open-window
  (lambda (width height)
    (if (> (glfwInit) 0)
	(if (> (glfwOpenWindow width height 0 0 0 0 0 0 65537) 0)
	    (begin (glfwSwapInterval 0) 1)
	    0)
	0)))

;; open window
(define res (open-window 640 480))

;; init gl
(gl-init 640 480)


;; change CWD to where your model lives!
(change-working-dir "/home/andrew/Documents/code/assimp/test/models/Collada")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; WARNING!!!
;; loading large models can blow the stack in which case you will
;; need to think about increasing the stack size "ulimit -s ....."
;; if the following line segfaults that will be the reason
;; (don't worry if you're using the assimp examples they're all tiny)
;;
(define model (load-asset "duck.dae"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make a display list
(define dlist (build-display-list model))

;; callback loop
(define gl-loop
  (lambda (time angle)
    (gl-callback model dlist angle)
    (callback (+ time 500) 'gl-loop (+ time 1000) (+ angle .05))))

;; start loop
(gl-loop (now) 0.0)