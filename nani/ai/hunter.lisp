; примерная стейт-машина
;
; если из обработчика приходит символ - меняем состояние на новое
(define hunter-state-machine { 
   'sleep { ; ничего не делаем, спим (изредка просыпаемся и ходим)
      'tick (lambda (I)
         (let ((counter (or ((I 'get) 'counter) 1)))
            ((I 'set) 'counter (+ counter 1))
            (if (zero? (mod counter 10)) 'walking)))
   }

   'look-around { ; ищем куда пойти
      'tick (lambda (I)  ; обработчик команды
         ;; (print "- look-around ------------------------------")
         ; найдем новое место куда идти
         (define destination (begin
            (define collision-data (level:get 'collision-data))
            (define H (size collision-data))         ; высота карты
            (define W (size (ref collision-data 1))) ; ширина карты

            ; быстро проверим можно ли туда дойти..
            (let loop ()
               (let ((x (rand! W))
                     (y (rand! H)))
                  (if (eq? (vector-ref (vector-ref collision-data y) x) 0)
                     (loop)
                     (cons x y))))))
         ; все, у нас есть новая цель в жизни
         ((I 'set) 'destination destination)
         ;; (print "new destination: " destination)
         'select-nextstep)
   }

   'select-nextstep {
      'tick (lambda (I)
         ;; (print "- select-next-step ------------------------------")
         (call/cc (lambda (ret)
            (define location ((I 'get-location)))
            (define r (cons
               (floor (car location))
               (floor (cdr location))))
            (define destination ((I 'get) 'destination))
            ; дошли куда хотели? поищем новую точку интереса
            ;; (if (and ;; was: (equal? r destination)
            ;;       (< (- (car destination) 0) (car location) (+ (car destination) 1))
            ;;       (< (- (cdr destination) 2) (cdr location) (+ (cdr destination) 1)))
            ;;    (ret 'look-around))
            (when (equal? r destination)
               (((I 'get) 'gotcha))
               (ret 'look-around))

            (define nextstep
               (let ((step (A* (level:get 'collision-data) r destination)))
                  ; сдвинем точку "ху" от начала клетки чтобы красивее ходить
                  ; не забываем, что наши нипы имеют некоторый рост
                  (if step (cons (+ (car step) (car r) 0.1) (+ (cdr step) (cdr r) 0.9)))))

            ((I 'set) 'nextstep nextstep)
            ;; (print "nextstep: " (inexact (car nextstep)) ", " (inexact (cdr nextstep)))
            ; если больше не можем дойти
            (if (not nextstep)
               (ret 'look-around))

            'walking)))
   }

   'walking {
      'tick (lambda (I)
         ;; (print "- walking ------------------------------")
         (call/cc (lambda (ret)
            (define location ((I 'get-location)))
            ;; (print "location: " (inexact (car location)) ", " (inexact (cdr location)))
            (define destination ((I 'get) 'destination))
            ;; (print "destination: " destination)
            (define nextstep ((I 'get) 'nextstep))
            ;; (print "next: " (inexact (car nextstep)) ", " (inexact (cdr nextstep)))

            ; закончили перемещение в следующую клетку?
            (if (and
                  (< (- (car nextstep) 0.076) (car location) (+ (car nextstep) 0.076))
                  (< (- (cdr nextstep) 0.066) (cdr location) (+ (cdr nextstep) 0.066)))
               (ret 'select-nextstep))
            
            ; хорошо, мы знаем куда надо идти, так что пойдем..
            (define collision-data (level:get 'collision-data))
            (define H (size collision-data))         ; высота карты
            (define W (size (ref collision-data 1))) ; ширина карты

            (define (at x y)
               (if (and (< 0 x W) (< 0 y H))
                  (let ((x (floor x))
                        (y (floor y)))
                     (vector-ref (vector-ref collision-data y) x))))

            (define (move dx dy)
               (define location ((I 'get-location)))
               (define newloc (cons
                  (+ (car location) dx)
                  (+ (cdr location) dy)))

               ; проверить можно ли ходить
               (unless (or
                     ;; (eq? (at (+ (car newloc) 0.077) (+ (cdr newloc) 0.065)) 0)
                     ;; (eq? (at (+ (car newloc) 0.923) (+ (cdr newloc) 0.065)) 0)
                     ;; (eq? (at (+ (car newloc) 0.923) (- (cdr newloc) 0.935)) 0)
                     ;; (eq? (at (+ (car newloc) 0.077) (- (cdr newloc) 0.935)) 0)
                     )
                  ((I 'set-location) newloc)
                  ; и повернемся в сторону движения
                  ((I 'set-orientation)
                     (cond
                        ((> dx 0) 1)
                        ((< dx 0) 3)
                        ((> dy 0) 2)
                        ((< dy 0) 0)
                        (else
                           (I 'get-orientation))))))

            (cond
               ((< (car location) (- (car nextstep) 0.076))
                  (move +0.151 0))
               ((> (car location) (+ (car nextstep) 0.076))
                  (move -0.151 0)))
            (cond
               ((< (cdr location) (- (cdr nextstep) 0.066))
                  (move 0 +0.131))
               ((> (cdr location) (+ (cdr nextstep) 0.066))
                  (move 0 -0.131)))

         ; остаемся в своем стейте
         #false))) ; 'sleep
   }
})
