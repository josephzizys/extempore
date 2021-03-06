;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Knight Example for Horde3D
;;
;; This example is pulled pretty much straight off the
;; Knight example that comes with Horde3D.
;;
;; 
;; NOTE!:
;; a) You will need to load the horde3d_lib.scm to bind to Horde3D
;; b) You will need to change the resource path to match your system!
;;    (resource path set on line 102)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define libglu (if (string=? "Linux" (sys:platform))
		   (sys:open-dylib "libGLU.so")
		   (if (string=? "Windows" (sys:platform))
		       (sys:open-dylib "Glu32.dll")
		       #f)))

(bind-lib libglu gluLookAt [void,double,double,double,double,double,double,double,double,double]*)
(bind-lib libglu gluPerspective [void,double,double,double,double]*)
(bind-lib libglu gluErrorString [i8*,i32]*)

(definec degToRad
  (lambda (f:float)
    (* f (/ 3.141592 180.0))))

;; globals
(bind-val _knight i32 0)
(bind-val light i32 0)
(bind-val _particleSys i32 0)
(bind-val _particleSys2 i32 0)
(bind-val _cam i32 0)
(bind-val _hdrPipeRes i32 0)
(bind-val _x float 5.0)
(bind-val _y float 3.0)
(bind-val _z float 19.0)
(bind-val _rx float 7.0)
(bind-val _ry float 15.0)
(bind-val _rz float 1.0)
(bind-val _velocity float 10.0)
(bind-val _curFPS float 30.0)
(bind-val _weight float 1.0)
(bind-val _animTime float 0.0)
(bind-val _forwardPipeRes i32 0)
(bind-val _deferredPipeRes i32 0)
(bind-val _fontMatRes i32 0)
(bind-val _panelMatRes i32 0)
(bind-val _logoMatRes i32 0)
(bind-val env i32 0)


(definec resize
  (lambda (width:float height:float)
    ;; resize viewport
    (h3dSetNodeParamI _cam H3DCamera_ViewportXI 0)
    (h3dSetNodeParamI _cam H3DCamera_ViewportYI 0)
    (h3dSetNodeParamI _cam H3DCamera_ViewportWidthI (ftoi32 width))
    (h3dSetNodeParamI _cam H3DCamera_ViewportHeightI (ftoi32 height))
    ;; set virtual cam params
    (h3dSetupCameraView _cam 45.0 (/ width height) 0.1 1000.0)
    (h3dResizePipelineBuffers _hdrPipeRes (ftoi32 width) (ftoi32 height))
    (h3dResizePipelineBuffers _forwardPipeRes (ftoi32 width) (ftoi32 height))
    1))


(definec h3d_init
  (let ((hand -1)
	(matRes -1)
	(envRes -1)
	(knightRes -1)
	(knightAnim1Res -1)
	(knightAnim2Res -1)
	(particleSysRes -1)
	)
    (lambda ()
      (if (h3dInit)
	  (printf "Successfully Inited Horde3D\n")
	  (begin (h3dutDumpMessages)
		 (printf "Failed to init Horde3D\n")))
      ;; set options
      (h3dSetOption H3DOptions_LoadTextures 1)
      (h3dSetOption H3DOptions_TexCompression 0)
      (h3dSetOption H3DOptions_FastAnimation 0)
      (h3dSetOption H3DOptions_MaxAnisotropy 4)
      (h3dSetOption H3DOptions_ShadowMapSize 2048)

      ;; add resources

      ;; set resources
      (set! _hdrPipeRes (h3dAddResource H3DResTypes_Pipeline "pipelines/hdr.pipeline.xml" 0))
      (set! _forwardPipeRes (h3dAddResource H3DResTypes_Pipeline "pipelines/forward.pipeline.xml" 0))
      
      (set! envRes (h3dAddResource H3DResTypes_SceneGraph "models/sphere/sphere.scene.xml" 0))
      (set! knightRes (h3dAddResource H3DResTypes_SceneGraph "models/knight/knight.scene.xml" 0))
      (set! knightAnim1Res (h3dAddResource H3DResTypes_Animation "animations/knight_order.anim" 0))
      (set! knightAnim2Res (h3dAddResource H3DResTypes_Animation "animations/knight_attack.anim" 0))
      (set! particleSysRes (h3dAddResource H3DResTypes_SceneGraph "particles/particleSys1/particleSys1.scene.xml" 0))

      ;; load resources
      (if (h3dutLoadResourcesFromDisk "/home/andrew/Documents/models/Horde3D")
	  (printf "succesfully loaded resouces\n")
	  (printf "failed to load resources\n"))

      ;; log any errors to Horde3D_Log.html
      (h3dutDumpMessages)                  

      ;; add camera
      (set! _cam (h3dAddCameraNode H3DRootNode "Camera" _hdrPipeRes))
      ;; add environment
      (set! env (h3dAddNodes H3DRootNode envRes))
      (h3dSetNodeTransform env 0.0 -20.0 0.0
			       0.0  0.0  0.0
			       20.0 20.0 20.0)
      
      ;; add knight
      (set! _knight (h3dAddNodes H3DRootNode knightRes))
      (h3dSetNodeTransform _knight 0.0 0.0   0.0
      			           0.0 180.0 0.0
      				   0.1 0.1   0.1)
      (h3dSetupModelAnimStage _knight 0 knightAnim1Res 0 "" #f)
      (h3dSetupModelAnimStage _knight 1 knightAnim2Res 0 "" #f)
      ;; attach particle system to hand joint
      (h3dFindNodes _knight "Bip01_R_Hand" H3DNodeTypes_Joint)
      (set! hand (h3dGetNodeFindResult 0))
      (set! _particleSys (h3dAddNodes hand particleSysRes))
      (h3dSetNodeTransform _particleSys 0.0  40.0 0.0
      			                90.0 0.0  0.0
      					1.0  1.0  1.0)
      ;; attached 2nd particle system to root node
      (set! _particleSys2 (h3dAddNodes H3DRootNode particleSysRes))
      
      ;; add light source
      (set! light (h3dAddLightNode H3DRootNode "Light1" 0 "LIGHTING" "SHADOWMAP"))
      (h3dSetNodeTransform light 0.0   15.0 10.0
			         -60.0 0.0  0.0
				 1.0   1.0  1.0)
      (h3dSetNodeParamF light H3DLight_RadiusF 0 30.0)
      (h3dSetNodeParamF light H3DLight_FovF 0 90.0)
      (h3dSetNodeParamI light H3DLight_ShadowMapCountI 1)
      (h3dSetNodeParamF light H3DLight_ShadowMapBiasF 0 0.01)
      (h3dSetNodeParamF light H3DLight_ColorF3 0 1.0)
      (h3dSetNodeParamF light H3DLight_ColorF3 1 0.8)
      (h3dSetNodeParamF light H3DLight_ColorF3 2 0.7)
      (h3dSetNodeParamF light H3DLight_ColorMultiplierF 0 1.0)
      
      (resize 1920.0 1200.0)
      
      1)))


(definec mainLoop
  (let ((_at 0.0)
	(fps:float 30.0))
    (lambda ()
      (set! _curFPS fps)
      (h3dSetOption H3DOptions_DebugViewMode 0.0)
      (h3dSetOption H3DOptions_WireframeMode 0.0)
      (set! _at (+ _at .03))
      
      (h3dSetModelAnimParams _knight 0 (* (dtof _at) 24.0) 24.0) ;_weight)
      
      (let ((cnt (h3dFindNodes _particleSys "" H3DNodeTypes_Emitter)))
      	(dotimes (i cnt)
      	  (h3dAdvanceEmitterTime (h3dGetNodeFindResult i) (/ 1.0 _curFPS))))
      (h3dSetNodeTransform _particleSys2 (* 12.0 (dtof (sin _at))) 2.0 (* 12.0 (dtof (cos _at))) 0.0 0.0 0.0 1.0 1.0 1.0)
      (let ((cnt3 (h3dFindNodes _particleSys2 "" H3DNodeTypes_Emitter)))	
      	(dotimes (i3 cnt3)
      	  (h3dAdvanceEmitterTime (h3dGetNodeFindResult i3) (/ 1.0 _curFPS))))

      (h3dSetNodeTransform light 7.0 15.0 20.0
			         -60.0 0.0  0.0
				 1.0  1.0  1.0)
            
      (h3dSetNodeTransform _cam (+ 0 _x) (+ 2 _y) (+ (* (dtof (sin _at)) 10) _z) (- 12 _rx) _ry 0.0 1.0 1.0 1.0)
      (h3dRender _cam)
      (h3dFinalizeFrame)
      (h3dClearOverlays)
      (h3dutDumpMessages)            
      1)))


;; standard impromptu callback
(define opengl-test
  (lambda (time degree)
    (mainLoop)
    (gl:swap-buffers pr2)
    (callback (+ time 500) 'opengl-test (+ time 1000) (+ degree 0.01))))


(define pr2 (gl:make-ctx ":0.0" #f 0.0 0.0 1024.0 768.0))
(h3d_init)
(resize 1024.0 768.0)
(opengl-test (now) 0.0)

