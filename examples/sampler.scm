;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This example shows how to use the builtin sampler
;;
;; You will first need to load and compile dsp_library.scm
;;
;; Then you're OK to go
;;
;; NOTE [at the moment compiling in a secondary thread is a little
;;      [flakey.  I'm working on this so in the mean time you'll
;;      [just have to put up with the audio delays while compiling
;;


;; first find a stereo audio file of some kind (not mp3 or aac)
;; ogg wav or aif should all be fine

;; then load up a few excerpts from the file
;; set-sampler-index takes
;; 1st: the instrument to load into (the default sampler is called 'sampler')
;; 2nd: the audio file to load from
;; 3rd: an index (from 0-127) to load into
;;      this should be the base frequency of the sample
;;      in other words a middle C sample should be loaded into 60.
;; 4th: an offset in samples (frames without channels)
;; 5th: a duration or length in samples to read

;; first let's just read in at one index
;; we'll choose middle C - 60
;; make sure your audio file is long enough for the params below!!
(set-sampler-index sampler "/tmp/audio.ogg" 60 500000 1000000)

;; playing back at 60 should playback without pitch shift
(play-note (now) sampler 60 80 100000)

;; anything else will pitch shift
;; floating point is OK
(play-note (now) sampler 67.25 80 100000)

;; a loop
(define loop
  (lambda (beat dur)
    (play sampler (random 48 72) 80 dur)
    (callback (*metro* (+ beat (* .5 dur))) 'loop
	      (+ beat dur)
	      dur)))

;; start loop
(loop (*metro* 'get-beat 4) 1)


;; read a directory full of samples
;; samples define a midi root i.e. 60.wav (for middle c)
;; must be stereo samples of type wav aif or ogg
(define-macro (load-sampler sampler path)
  `(let ((files (sys:directory-list ,path)))
     (for-each (lambda (f)
		 (if (regex:match? f "^([0-9]*)\.(wav|aif|aiff|ogg)$")		     
		     (let ((result (regex:matched f "^([0-9]*)\.(wav|aif|aiff|ogg)$")))
		       (set-sampler-index ,sampler (string-append ,path "/" f)
		       			  (string->number (cadr result)) 0 0))))
	       files)))

;; load audio samples
;; I'm using piano samples
(load-sampler sampler "/home/andrew/Documents/samples/piano")


(define loop2
  (lambda (beat dur root)
    (play 3 sampler 36 100 dur)
    (for-each (lambda (p offset)
		(play (+ offset) sampler p 100 (* 2. dur)))
	      (pc:make-chord 40 84 7
			     (pc:chord root (if (member root '(10 8))
						'^7
						'-7)))
	      '(1/3 1 3/2 1 2 3 13/3))
    (callback (*metro* (+ beat (* .5 dur))) 'loop2 (+ beat dur)
	      dur
	      (if (member root '(0 8))
		  (random '(2 7 10))
		  (random '(0 8))))))


(loop2 (*metro* 'get-beat 4) 4 0)



;; make some more samplers
(define-sampler sampler2 sampler-note sampler-fx)
(define-sampler sampler3 sampler-note sampler-fx)

;; add new samplers to dsp
(definec:dsp dsp
  (lambda (in time chan dat)
    (cond ((< chan 2.0) (+ (synth in time chan dat)
			   (sampler in time chan dat)
			   (sampler2 in time chan dat)
			   (sampler3 in time chan dat)))
	  (else 0.0))))

;; load new samplers