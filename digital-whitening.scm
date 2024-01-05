(script-fu-register
 "script-fu-digital-whitening"
 "Digital whitening"
 "Digital whitening for macrofossils (D.N. Kiselev 2021)."
 "Raffael Mancini"
 "copyright 2024, Raffael Mancini, Musée National d'Histoire Naturelle Luxembourg"
 "January 04, 2024"
 "" ;image type that the script works on
 SF-FILENAME    "Base image" ""
 SF-DIRNAME     "Other images directory"  "./"
 SF-STRING      "Other images pattern" "*.jpg"
 SF-VALUE       "Background selection threshold (0-100)" "5"
 SF-VALUE       "Histogram expansion (0-1). Small has stronger effect." "0.3"
 SF-TOGGLE      "Expand histogram" 1
 SF-TOGGLE      "Flatten layers" 1)

(script-fu-menu-register "script-fu-digital-whitening" "<Image>/Script-Fu/Paleontology")

;; Helper
(define (remove fn lst)
  (let loop ((lst lst) (result '()))
    (if (null? lst)
        (reverse result)
        (let ((item (car lst)))
          (loop (cdr lst)
                (if (fn item) result (cons item result)))))))

(define (script-fu-digital-whitening base-image-name input-directory file-pattern
				     selection-threshold expansion
				     expand-histogram flatten)
  (let* ((pattern (string-append (string-append input-directory "/")
				 file-pattern))
	 (file-names (cadr (file-glob pattern 0)))
	 (file-name-base base-image-name)
	 (file-names-rest (remove (lambda (fn) (equal? fn file-name-base))
				  file-names))
	 (image (car (gimp-file-load RUN-NONINTERACTIVE file-name-base "base-image")))
	 (base-layer (car (gimp-image-get-active-layer image)))
	 (layer-group-top (car (gimp-layer-group-new image)))
	 (layers (begin
		   (gimp-image-insert-layer image layer-group-top 0 0)
		   (map (lambda (file-name)
			(let ((new-layer
			       (car (gimp-file-load-layer RUN-NONINTERACTIVE image file-name))))
			  (gimp-image-insert-layer image new-layer layer-group-top 0)))
		      file-names-rest)))
	 )

    (gimp-image-convert-precision image
				  PRECISION-U16-LINEAR)

    ;; Top layers:
    ;; Invert, Desaturate and make transparent
    (let* ((layers (vector->list (cadr (gimp-item-get-children layer-group-top))))
	   (layer-count (length layers))
	   (opacity (/ (/ 100 layer-count) 1)))
      (map (lambda (layer)
	     (gimp-drawable-invert layer FALSE)
	     (gimp-drawable-desaturate layer DESATURATE-LIGHTNESS)
	     (gimp-layer-set-opacity layer opacity))
	   layers))

    ;; Create SELECTION for layer mask
    (gimp-image-set-active-layer image base-layer)
    (gimp-context-set-feather TRUE)
    (gimp-context-set-feather-radius 3 3)
    (gimp-context-set-sample-merged TRUE) ; Sample all layers
    (gimp-context-set-sample-threshold-int selection-threshold) ; 4
    (gimp-image-select-contiguous-color image CHANNEL-OP-ADD base-layer
					10 10) ; Select background

    ;; FILL background of base-layer
    (gimp-drawable-edit-fill base-layer FILL-WHITE)
    
    (gimp-selection-invert image)

    ;; Add selection as mask to top layer group (this makes background of base image shine through) and to base-layer (for later equalization)
    (gimp-layer-add-mask layer-group-top
			 (car (gimp-layer-create-mask layer-group-top ADD-MASK-SELECTION)))
    (gimp-selection-clear image)

    ;; BACKGROUND ops
    (let* ((layer-ids (cdr (gimp-image-get-layers image)))
	   (layer (car (gimp-image-get-layer-by-name image "Background"))))
      (gimp-drawable-desaturate layer DESATURATE-LIGHTNESS))

    ;; Finally FLATTEN
    (if (= flatten 1)
	(gimp-image-flatten image))

    ;; Expand histogram
    (if (= expand-histogram 1)
	(let* ((layer-ids (cdr (gimp-image-get-layers image)))
	       (layer (car (gimp-image-get-layer-by-name image "Background")))
	       (hist (gimp-drawable-histogram layer HISTOGRAM-VALUE 0 1))
	       (median (caddr hist))
	       (sp (mk-spline (/ expansion 2.0) median)))
	  (gimp-drawable-curves-spline layer HISTOGRAM-VALUE 8 sp)))
          
    ;; Finally SHOW image in interface
    (gimp-display-new image)
    (gimp-image-undo-enable image)))

(define (mk-spline expansion median)
  "Spline for curves oparator. Expands histogram around histogram
median. Expansion of 0 maps middle of original to whole output
histogram. Expansion of 1 makes no change for a balanced histogram or
recenters histogram location otherwise."
  (list->vector
   (list 0.0 0.0
	 (max (- median expansion) 0.0) 0.1
	 (min (+ median expansion) 1.0) 0.9
	 1.0 1.0)))

