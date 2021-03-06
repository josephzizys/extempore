;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Simplest possible audio example
; Just eval each expression in turn
;
; Extempore provides very low-level audio support.  
; Essentially the routine you choose to set using dsp:set! 
; is responsible for directly filling the audio-devices 
; audio-buffer. In practice this means that you have to
; MUST use the extempore compiler to write your 
; DSP code.  If you don't know anything about the 
; extempore compiler you should start by looking
; at the extempore_lang.scm example.
;


;; compile sample by sample dsp code
(definec dsp
  (lambda (in:double time:double channel:double	data:double*)
    (* .2 (random))))


;; set compiled function named "dsp" to be the dsp callback
;; once this is set any recompilation of the function
;; named "dsp" will hot-swap automatically.
;; in other words you should only need to call dsp:set! once.
(dsp:set! dsp)


;; recompile dsp to produce two sine wave in left and right
(definec dsp
  (lambda (in:double time:double channel:double	data:double*)
    (cond ((= channel 0.0)
           (* 0.5 (sin (* 3.141592 2.0 200.0 (/ time 44100.0)))))
          ((= channel 1.0)
           (* 0.5 (sin (* 3.141592 2.0 210.0 (/ time 44100.0)))))
          (else	0.0))))


;; abstract out an oscillator function
(definec make-oscil
   (lambda (phase)
      (lambda (amp freq)
         (let ((inc (* 3.141592 (* 2.0 (/ freq 44100.)))))
            (set! phase (+ phase inc))
            (* amp (sin phase))))))


;; same example as above but using oscillator abstraction
(definec dsp
  (let ((osc1 (make-oscil 0.0))
	(osc2 (make-oscil 0.0)))
    (lambda (in:double time:double channel:double data:double*)
      (cond ((= channel 1.0) (osc1 0.5 200.0))
	    ((= channel 0.0) (osc2 0.5 210.0))
	    (else 0.0)))))


;; slightly more complex example
(definec dsp
  (let ((oscs (make-array 9 [double,double,double]*)))
    (dotimes (i 9)
       (aset! oscs i (make-oscil 0.0)))
    (lambda (a:double b:double c:double d:double*)
      (cond ((= c 0.0) ;; left channel
             (+ ((aref oscs 0) (+ 0.3 ((aref oscs 2) 0.2 1.0)) 60.0)
		((aref oscs 3) 0.2 220.0)
		((aref oscs 4) 0.2 (+ 400. ((aref oscs 5) 200. .1)))
		((aref oscs 6) 0.1 900.0)))
            ((= c 1.0) ;; right channel                                                                       
             ((aref oscs 7) 0.3 (+ 220.0 ((aref oscs 8) 110.0 20.0))))
            (else 0.0))))) ;; any remaining channels                                                          


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; a simple example of "event" level control
;; 
;; or how to to control DSP code from inside
;; a scheme temporal recursion 


;; modify one of the examples from above
;; adding freq1 and freq2 into closure environment
(definec dsp
  (let ((osc1 (make-oscil 0.0))
	(osc2 (make-oscil 0.0))
	(freq1 220.0)
	(freq2 220.0))
    (lambda (in:double time:double channel:double data:double*)
      (cond ((= channel 1.0) (osc1 0.3 freq1))
	    ((= channel 0.0) (osc2 0.3 freq2))
	    (else 0.0)))))

;; write accessor function for modification
;; of closure slots freq1 and freq2
(definec change-freq
  (lambda (freq1 freq2)
    (dsp.freq1:double freq1)
    (dsp.freq2:double freq2)))


;; a "normal scheme" temporal recursion
;; for event level control
(define loop
  (lambda (time freq dir)
    (change-freq
     (* 1.0 (random 100 500))
     (* 1.0 freq))
    (callback time 'loop (+ time (* 20.0 freq))
	      (dir freq 50.0)
	      (cond ((> freq 600.0) -)
		    ((< freq 300.0) +)
		    (else dir)))))
		  
;; start loop
(loop (now) 220.0 +)
