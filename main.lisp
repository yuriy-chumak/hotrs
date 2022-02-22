#!/usr/bin/ol

; ----------------------------------
; зададим размеры графического окна
(define-library (lib gl config)
(export config) (import (otus lisp))
(begin
   (define config {
      ; напомню, что мы используем фиксированный шрифт размера 9*16
      'width  (* 1  9 80)      ; 80 знакомест в ширину
      'height (* 1 16 25)      ; 25 знакомест в высоту
      'scale  32               ; шкала увеличения
   })))
(import (lib gl config))

; -=( main )=------------------------------------
; подключаем графические библиотеки, создаем окно
(import (lib gl2))
(gl:set-window-title "The House of the Rising Sun")
(import (otus ffi))
(import (lib soil))

; -=( сразу нарисуем сплеш )=---------------------------
(glOrtho 0 1 1 0 0 1)
(glEnable GL_TEXTURE_2D)

(define id
   (let ((file (file->bytevector "splash.png")))
      (SOIL_load_OGL_texture_from_memory file (size file) SOIL_LOAD_RGBA SOIL_CREATE_NEW_ID 0)))
(glBindTexture GL_TEXTURE_2D id)
(glBegin GL_QUADS)
   ; рисуем на весь экран квадратик с текстурой
   (for-each (lambda (xy)
         (glTexCoord2f (car xy) (cdr xy))
         (glVertex2f (car xy) (cdr xy)))
      '((0 . 0) (1 . 0) (1 . 1) (0 . 1)))
(glEnd)
(glDisable GL_TEXTURE_2D)
(gl:SwapBuffers (await (mail 'opengl ['get 'context]))) ; todo: make a function
(glDeleteTextures 1 (list id)) ; и спокойно удалим сплеш текстуру

; ----------------------------------------------------------
(define-library (enable vsync)
(export)
(import (scheme core)
   (owl async))
(cond-expand
   (Windows
      (import (OpenGL WGL EXT swap_control))
      (begin
         (if WGL_EXT_swap_control
            (wglSwapIntervalEXT 1))))
   (else
      (import (OpenGL GLX EXT swap_control))
      (begin
         (define context (await (mail 'opengl ['get 'context]))) ; todo: make a function

         ; https://gist.github.com/Cloudef/9103499
         (if (and context glXSwapIntervalEXT)
            (glXSwapIntervalEXT (ref context 1) (ref context 3) 1))))))

;; ; -------------------------------------------------------
;; ; теперь запустим текстовую консольку
;; (import (lib gl console))
;; (import (scheme dynamic-bindings))
; (define *guess* (make-parameter #f))

;; ; временное окно дебага (покажем fps):
;; (define fps (create-window 50 24 10 1))
;; (define started (time-ms)) (define time '(0))
;; (define frames '(0 . 0))

;; (define npc-targets '(0 . 0))

;; (set-window-writer fps (lambda (print)
;;    (set-car! frames (+ (car frames) 1))
;;    (let ((now (time-ms)))
;;       (if (> now (+ started (car time) 1000))
;;          (begin
;;             (set-cdr! frames (car frames))
;;             (set-car! frames 0)
;;             (set-car! time (- now started)))))
;;    (print GREEN (car npc-targets) "    ")
;;    (print GRAY (cdr frames) " fps")
;; ))

;; (define info (create-window 0 0 20 1))
;; (coroutine 'meet (lambda ()
;;    (let this ((itself #false))
;;       (let*((envelope (wait-mail))
;;             (sender msg envelope))
;;          (this
;;             (if msg msg (begin (mail sender itself) itself)))))))
;; (set-window-writer info (lambda (print)
;;    (let ((meet (await (mail 'meet #false))))
;;       (if (string? meet)
;;          (print "Hello, " meet "!")))))


;; (define gathered-window (create-window 3 23 20 1))
;; (define gathered (cons 0 0))
;; (set-window-writer gathered-window (lambda (print)
;;    (print "Alister got " (car gathered) " coins, and Bambi got " (cdr gathered) " coins.")))

; ----------------
; музычка...
;,load "music.lisp" ; временно отключена

;; ; остальные библиотеки (в том числе игровые)
(import (lib keyboard))
;; (import (lib math))
;; (import (otus random!))
(import (otus random!))
;; (import (scheme misc))
;; (import (file xml))
;; (import (scheme dynamic-bindings))

;; ; -=( level )=-----------------
;; ;     заведует игровой картой
,load "nani/creature.lisp"
,load "nani/level.lisp"
;; ,load "nani/ai.lisp"

;; ;; ;;; -=( creatures )=-----------------
;; ;; ;;;  'creatures - заведует всеми живыми(или оживленными) созданиями

; ============================================================================
; 1. Загрузим первый игровой уровень
(level:load "floor-1.json")

;; ; временная функция работы с level-collision
;; (define collision-data (level:get-layer 'collision))

;; (define H (length collision-data))       ; высота уровня
;; (define W (length (car collision-data))) ; ширина уровня

;; ; временная функция: возвращает collision data
;; ;  по координатам x,y на карте
;; (define (at x y)
;;    (if (and (< -1 x W) (< -1 y H))
;;       (lref (lref collision-data y) x)))
(define CELL-WIDTH (await (mail 'level ['get 'tilewidth])))
(define CELL-HEIGHT (await (mail 'level ['get 'tileheight])))

;; ;; ; --------------------------------------------------------------------
;; ;; ; окно, через которое мы смотрим на мир

;; ;              x-left         y-left    x-right          y-right
;; ;(define window (vector (+ -32 -800) -32 (+ 3645 32 -800) (+ 2048 32)))
(define window [0 0 854 480])

;; (define (resize scale) ; изменение масштаба
;;    (let*((x (floor (/ (+ (ref window 3) (ref window 1)) 2)))
;;          (w (floor (* (- (ref window 3) (ref window 1)) (/ scale 2))))
;;          (y (floor (/ (+ (ref window 4) (ref window 2)) 2)))
;;          (h (floor (* (- (ref window 4) (ref window 2)) (/ scale 2)))))
;;       (set-ref! window 1 (- x w))
;;       (set-ref! window 2 (- y h))
;;       (set-ref! window 3 (+ x w))
;;       (set-ref! window 4 (+ y h))))
;; (define (move-window dx dy) ; сдвинуть окно
;;    (let*((w (- (ref window 3) (ref window 1))) ;window width
;;          (h (- (ref window 4) (ref window 2))));window height
;;       (set-ref! window 1 (+ (ref window 1) (floor (* dx w))))
;;       (set-ref! window 2 (- (ref window 2) (floor (* dy h))))
;;       (set-ref! window 3 (+ (ref window 3) (floor (* dx w))))
;;       (set-ref! window 4 (- (ref window 4) (floor (* dy h))))))
(define (move-window dx dy) ; сдвинуть окно
   (set-ref! window 1 (+ (ref window 1) (floor dx)))
   (set-ref! window 2 (- (ref window 2) (floor dy)))
   (set-ref! window 3 (+ (ref window 3) (floor dx)))
   (set-ref! window 4 (- (ref window 4) (floor dy))))

;; ; функция перевода экранных координат в номер тайла, на который они попадают
;; (define (xy:screen->tile xy)
;;    (let ((x1 (ref window 1)) (x2 (ref window 3))
;;          (y1 (ref window 2)) (y2 (ref window 4)))
;;    (let ((x2-x1 (- x2 x1)) (y2-y1 (- y2 y1))
;;          (w (ref gl:window-dimensions 3)) (h (ref gl:window-dimensions 4)))
;;    (let ((X (floor (+ x1 (/ (* (car xy) x2-x1) w))))
;;          (Y (floor (+ y1 (/ (* (cdr xy) y2-y1) h)))))
;;    (let ((w (level:get 'tilewidth))
;;          (h (level:get 'tileheight)))
;;    (let ((x (+ (/ X w) (/ Y h)))
;;          (y (- (/ Y h) (/ X w))))
;;       (cons (floor x) (floor y))))))))

;; ;; ;(resize 1/3) ; временно: увеличим карту в 3 раза

; init
(glShadeModel GL_SMOOTH)
(glBlendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA)
(gl:hide-cursor)

;; ;; ; служебные переменные
;; ;; (define timestamp (box 0))
;; (define calculating-world (box 0))
;; (define (world-busy?)
;;    (less? 0 (unbox calculating-world)))

; -----------------------------------------------------------------------------------------------

; попробуем создать стейт-машину одного нпс (для примера пусть он просто бегает по карте)
; будем гонять перса alister

,load "nani/ai.lisp"
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

; живи!
(define alister ((await (mail 'level ['get 'npcs])) 'alister))
(print "alister: " alister)
((alister 'set) 'state-machine hunter-state-machine) ; todo: rename to soul? ))
((alister 'set) 'state 'look-around)
((alister 'set) 'gotcha (lambda () #|(set-car! gathered (+ (car gathered) 1))|# #f))

(define bambi ((await (mail 'level ['get 'npcs])) 'bambi))
(print "bambi: " bambi)
((bambi 'set) 'state-machine hunter-state-machine) ; todo: rename to soul? ))
((bambi 'set) 'state 'look-around)
((bambi 'set) 'gotcha (lambda () #|(set-cdr! gathered (+ (cdr gathered) 1))|# #f))





; -----------------------------------------------------------------------------------------------
(define time (box (cdr (syscall 96))))

; draw
(define (playing-level-screen mouse)
   (define delta ; in usec (microseconds)
      (let*((ss us (uncons (syscall 96) #f)))
         (define delta (mod (+ (- us (unbox time)) 1000000) 1000000)) ; мы не ожидаем задержку больше чем 1 секунда
         (set-car! time us)
         delta))


;;    ; тут мы поворачиваем нашего героя в сторону мышки
;;    (unless (world-busy?) (if (> ((hero 'get) 'health) 0)
;;       (let*((mousetile (xy:screen->tile mouse))
;;             (herotile ((hero 'get-location)))
;;             (dx (- (car mousetile) (car herotile)))
;;             (dy (- (cdr mousetile) (cdr herotile))))
;;          (cond
;;             ((and (= dx 0) (< dy 0))
;;                ((hero 'set-orientation) 0))
;;             ((and (= dx 0) (> dy 0))
;;                ((hero 'set-orientation) 4))
;;             ((and (< dx 0) (= dy 0))
;;                ((hero 'set-orientation) 6))
;;             ((and (> dx 0) (= dy 0))
;;                ((hero 'set-orientation) 2))

;;             ((and (= dx +1) (= dy +1))
;;                ((hero 'set-orientation) 3))
;;             ((and (= dx -1) (= dy +1))
;;                ((hero 'set-orientation) 5))
;;             ((and (= dx -1) (= dy -1))
;;                ((hero 'set-orientation) 7))
;;             ((and (= dx +1) (= dy -1))
;;                ((hero 'set-orientation) 1))
;;          ))))

;; ;;    ; просто регулярные действия
;; ;;    (let*((ss ms (clock))
;; ;;          (i (mod (floor (/ (+ (* ss 1000) ms) (/ 1000 4))) 4)))

;; ;;       (unless (eq? i (unbox timestamp))
;; ;;          (begin
;; ;;             (set-car! timestamp i)

;; ;;             ; надо послать нипам 'tick, а вдруг они захотят с ноги на ногу попереминаться...

;; ;;             ;; ; события нипов пускай остаются асинхронными,
;; ;;             ;; ; просто перед рисованием убедимся что они все закончили свою работу
;; ;;             ;; (for-each (lambda (id)
;; ;;             ;;       (mail id ['process-event-transition-tick]))
;; ;;             ;;    (await (mail 'creatures ['get 'skeletons])))
;; ;;          )))

   ; теперь можем и порисовать: очистим окно и подготовим оконную математику
   (glClearColor 0.0 0.0 0.0 1)
   (glClear GL_COLOR_BUFFER_BIT)
   (glLoadIdentity)
   (glOrtho (ref window 1) (ref window 3) (ref window 4) (ref window 2) -1 1)

   ; зададим пропорциональное увеличение
   (glScalef (config 'scale 40) (config 'scale 40) 1)

   (glEnable GL_TEXTURE_2D)
   (glEnable GL_BLEND)

   ; теперь попросим уровень отрисовать себя
   ; (герой входит в общий список npc)
   (define creatures
      (map (lambda (creature)
            (define npc (cdr creature))
            [ ((npc 'get-location))
              ((npc 'get-animation-frame))])
         ; отсортируем npc снизу вверх
         (sort (lambda (a b)
                  (< (cdr (((cdr a) 'get-location)))
                     (cdr (((cdr b) 'get-location)))))
               (ff->alist (await (mail 'level ['get 'npcs]))))))

   ;; (print "creatures: " creatures)
   (level:draw creatures)

   ; окошки, консолька, etc.
   ;; (render-windows)

   ; let's draw mouse pointer
   (glScalef (/ 1 (config 'scale 40)) (/ 1 (config 'scale 40)) 1)
   (when mouse
      (define viewport '(0 0 0 0))
      (glGetIntegerv GL_VIEWPORT viewport)

      (let*((tile (getf (level:get 'tileset)
                        (+ (level:get-gid 'pointer)
                           (if (world-busy?) 1 0))))
            (w (config 'scale 40)) ;(- (ref window 3) (ref window 1))) ;  размер курсора
            (st (ref tile 5))
            (dx (/ (- (car mouse) (lref viewport 0)) (lref viewport 2)))
            (dy (/ (- (cdr mouse) (lref viewport 1)) (lref viewport 3)))
            ; window mouse to opengl mouse:
            (x (+ (ref window 1) (* dx (- (ref window 3) (ref window 1)))))
            (y (+ (ref window 2) (* dy (- (ref window 4) (ref window 2))))))
         (glEnable GL_TEXTURE_2D)
         (glEnable GL_BLEND)
         (glBindTexture GL_TEXTURE_2D (ref tile 1))
         (glBegin GL_QUADS)
            (glTexCoord2f (ref st 1) (ref st 2))
            (glVertex2f x y)

            (glTexCoord2f (ref st 3) (ref st 2))
            (glVertex2f (+ x w) y)

            (glTexCoord2f (ref st 3) (ref st 4))
            (glVertex2f (+ x w) (+ y w))

            (glTexCoord2f (ref st 1) (ref st 4))
            (glVertex2f x (+ y w))
         (glEnd)))

      ; герой всегда имеет имя 'hero
      (define hero ((await (mail 'level ['get 'npcs])) 'hero #f))
      ; ----- порталы -----------------------------
      (let*((location ((hero 'get-location)))
            (hx (car location))
            (hy (cdr location))
            (portals (ff->alist (level:get 'portals))))
         (for-each (lambda (portal)
;               (print "testing portal " portal)
               (let ((x (portal 'x))
                     (y (portal 'y))
                     (width  (portal 'width))
                     (height (portal 'height)))
                  ; прямоугольники пересекаются?
                  (unless (or
                        (< (+ hx 1) x)
                        (> (- hy 1) (+ y height))
                        (> hx (+ x width))
                        (< hy y))
                     (define target (portal 'target))
                     (define level (car target))
                     (define spawn (cdr target))

                     (print "target: " target)

                     (when level
                        (level:load (string-append (symbol->string level) ".json"))

                        ; move hero to level:
                        (level:set 'npcs
                           (put (level:get 'npcs) 'hero hero))

                        (define spawn (getf (level:get 'spawns) (cdr target)))
                        ((hero 'set-location) (cons (spawn 'x) (spawn 'y)))
                        
                        )
                  )))
            (map cdr portals)))


   ; -------------
   ; а не хотим ли мы с кем-нибудь пообщаться?
      ;; (mail 'meet (call/cc (lambda (return)
      ;;    (let*((location ((hero 'get-location)))
      ;;          (hx (car location))
      ;;          (hy (cdr location)))
      ;;       (for-each (lambda (pair)
      ;;             (define name (car pair))
      ;;             (unless (eq? name 'hero)
      ;;                (define npc (((cdr pair) 'debug)))
      ;;                (let*((x y (uncons (npc 'location) #f)))
      ;;                   (unless (or
      ;;                         (< (+ hx 1) x)
      ;;                         (> (- hy 1) (+ y 1))
      ;;                         (> hx (+ x 1))
      ;;                         (< hy y))
      ;;                      (return (symbol->string name))))))
      ;;          (ff->alist (level:get 'npcs))))
      ;;    #null)))


   ; -------------
   ; обработчик состояния клавиатуры
   ;  внимание, это "состояние", а не "события"!
   ;  посему можно обрабатывать сразу несколько нажатий клавиатуры одновременно
   (if (key-pressed? KEY_ESC) (halt 0))

   ; -------------------------------------
   ;; функции работы с "тут можно ходить"
   ; временная функция работы с level-collision
   (define collision-data (level:get 'collision-data))
   (define W (level:get 'width)) ; ширина уровня
   (define H (level:get 'height)) ; высота уровня

   ; временная функция: возвращает collision data
   ;  по координатам x,y на карте
   (define (at x y)
      (let ((x (+ (floor x) 1))
            (y (+ (floor y) 1)))
         (if (and (< 0 x W) (< 0 y H))
            (ref (ref collision-data y) x))))

   ; двигать героя
   (define (move dx dy)
      (define loc ((hero 'get-location)))

      (define newloc (cons
         (+ (car loc) dx)
         (+ (cdr loc) dy)))
      ; проверить можно ли ходить
      (unless (or
            (eq? (at (+ (car newloc) 0.1) (+ (cdr newloc) 0.05)) 0)
            (eq? (at (+ (car newloc) 0.9) (+ (cdr newloc) 0.05)) 0)
            (eq? (at (+ (car newloc) 0.9) (- (cdr newloc) 0.20)) 0)
            (eq? (at (+ (car newloc) 0.1) (- (cdr newloc) 0.20)) 0))

         ; левая граница
         (let loop ()
            (when (< (* (car newloc) (config 'scale))
                     (+ (ref window 1) (/ (- (ref window 3) (ref window 1)) 5)))
               (move-window -1 0)
               (loop)))
         ; правая граница
         (let loop ()
            (when (> (* (car newloc) (config 'scale))
                     (- (ref window 3) (/ (- (ref window 3) (ref window 1)) 5)))
               (move-window +1 0)
               (loop)))
         ; верхняя граница
         (let loop ()
            (when (< (* (cdr newloc) (config 'scale))
                     (+ (ref window 2) (/ (- (ref window 4) (ref window 2)) 5)))
               (move-window 0 +1)
               (loop)))
         ; нижняя граница
         (let loop ()
            (when (> (* (cdr newloc) (config 'scale))
                     (- (ref window 4) (/ (- (ref window 4) (ref window 2)) 5)))
               (move-window 0 -1)
               (loop)))

         ((hero 'set-location)
            newloc))

      ((hero 'set-orientation)
         (cond
            ((> dx 0) 1)
            ((< dx 0) 3)
            ((> dy 0) 2)
            ((< dy 0) 0)
            (else
               (hero 'get-orientation))))
   )

   ;; todo: дебаг-интерфейс, позволяющий двигать окно просмотра по всей карте:
   (if (key-pressed? KEY_RIGHT) (move   (*    0.00392 delta) 0)) ; right +0.051
   (if (key-pressed? KEY_LEFT)  (move   (- (* 0.00392 delta)) 0)) ; left +0.051
   (if (key-pressed? KEY_UP)    (move 0 (- (* 0.00238 delta)))) ; up
   (if (key-pressed? KEY_DOWN)  (move 0 (*    0.00238 delta))) ; down

   ;; (when (key-pressed? KEY_1) ; todo: move hero to new location
   ;;    (level:load "floor-1.json"))

   ;; (when (key-pressed? KEY_2) ; todo: move hero to new location
   ;;    (level:load "floor-2.json"))

;;    (if (key-pressed #x3d) (resize 0.9)) ;=
;;    (if (key-pressed #x2d) (resize 1.1)) ;-
)

;; ;; ; --------------------------------------------
;; ;; ;; (define (unX x y tw th)
;; ;; ;;    (+ (- (* x (/ w 2))
;; ;; ;;          (* y (/ w 2)))
;; ;; ;;       (- (/ (* width w) 4) (/ w 2))))

;; ;; ;; (define (unY x y tw th)
;; ;; ;;    (+ (+ (* x (/ h 2))
;; ;; ;;          (* y (/ h 2)))
;; ;; ;;       (- h th)))
;; ;; ; --------------------------------------------


;; ; keyboard
;; ; обработчик событий клавиатуры
;; ;  внимание, это "события", а не "состояние"!!!
(gl:set-keyboard-handler (lambda (key)
   (print "key: " key)

   ;; ; карта
   ;; (define collision-data (level:get 'collision-data))
   ;; (define W (level:get 'width)) ; ширина уровня
   ;; (define H (level:get 'height)) ; высота уровня

   ;; ; временная функция: возвращает collision data
   ;; ;  по координатам x,y на карте
   ;; (define (at x y)
   ;;    (let ((x (+ (floor x) 1))
   ;;          (y (+ (floor y) 1)))
   ;;       (if (and (< 0 x W) (< 0 y H))
   ;;          (ref (ref collision-data y) x))))

   ;; ; герой собственной персоной
   ;; (define hero ((await (mail 'level ['get 'npcs])) 'hero #f))

   ;; ; двигать героя
   ;; (define (move dx dy)
   ;;    (define loc ((hero 'get-location)))

   ;;    (define newloc (cons
   ;;       (+ (car loc) dx)
   ;;       (+ (cdr loc) dy)))
   ;;    ; проверить можно ли ходить
   ;;    (unless (or
   ;;          (eq? (at (+ (car newloc) 0.1) (+ (cdr newloc) 0.05)) 0)
   ;;          (eq? (at (+ (car newloc) 0.9) (+ (cdr newloc) 0.05)) 0)
   ;;          (eq? (at (+ (car newloc) 0.9) (- (cdr newloc) 0.20)) 0)
   ;;          (eq? (at (+ (car newloc) 0.1) (- (cdr newloc) 0.20)) 0))

   ;;       ; левая граница
   ;;       (let loop ()
   ;;          (when (< (* (car newloc) (config 'scale))
   ;;                   (+ (ref window 1) (/ (- (ref window 3) (ref window 1)) 5)))
   ;;             (move-window -1 0)
   ;;             (loop)))
   ;;       ; правая граница
   ;;       (let loop ()
   ;;          (when (> (* (car newloc) (config 'scale))
   ;;                   (- (ref window 3) (/ (- (ref window 3) (ref window 1)) 5)))
   ;;             (move-window +1 0)
   ;;             (loop)))
   ;;       ; верхняя граница
   ;;       (let loop ()
   ;;          (when (< (* (cdr newloc) (config 'scale))
   ;;                   (+ (ref window 2) (/ (- (ref window 4) (ref window 2)) 5)))
   ;;             (move-window 0 +1)
   ;;             (loop)))
   ;;       ; нижняя граница
   ;;       (let loop ()
   ;;          (when (> (* (cdr newloc) (config 'scale))
   ;;                   (- (ref window 4) (/ (- (ref window 4) (ref window 2)) 5)))
   ;;             (move-window 0 -1)
   ;;             (loop)))

   ;;       ((hero 'set-location)
   ;;          newloc))

   ;;    ((hero 'set-orientation)
   ;;       (cond
   ;;          ((> dx 0) 1)
   ;;          ((< dx 0) 3)
   ;;          ((> dy 0) 2)
   ;;          ((< dy 0) 0)
   ;;          (else
   ;;             (hero 'get-orientation))))
   ;; )

   ;; (case key
   ;;    (113 ; left
   ;;       (move -0.051 0))
   ;;    (114 ; right
   ;;       (move +0.051 0))
   ;;    (111 ; up
   ;;       (move 0 -0.031))
   ;;    (116 ; down
   ;;       (move 0 +0.031))

   ;;    (#x18 ; q - quit
   ;;       ;(mail 'music ['shutdown])
   ;;       (shutdown 1)))
))

;; (gl:set-mouse-handler (lambda (button x y)
;;    (print "mouse: " button " (" x ", " y ")")
;;    (unless (world-busy?) ; если мир сейчас не просчитывается (todo: оформить отдельной функцией)
;;       (cond
;;          ((and (eq? button 1) (> ((hero 'get) 'health) 0))
;;             (set-car! calculating-world (+ (unbox calculating-world) 1))
;;             (let ((tile (xy:screen->tile (cons x y))))
;;                (mail 'game ['go tile])))
;;          ;; ((eq? button 3) ; ПКМ
;;          ;;    (set-car! calculating-world (+ (unbox calculating-world) 1))
;;          ;;    (mail 'game ['turn]))
;;          (else
;;             ; nothing
;;             #true))
;;    )))

(define (changing-level-screen mouse)
   ; nothing
   (if (key-pressed? KEY_ESC) (halt 1))
   #false)

(define renderer (box playing-level-screen))
(gl:set-renderer (lambda (mouse)
   ; временно обработаем физику тут, потом заберем ее отдельно
   (for-each (lambda (pair)
         (define npc (cdr pair))
         (let ((state ((npc 'get) 'state)))
            (when state
               (let ((state (((npc 'get) 'state-machine) state)))
                  (when state
                     (let*((tick (state 'tick (lambda (I) #f)))
                           (new (tick npc)))
                        ;(if new (print "new state: " new))
                        ; если произошла смена стейта - установим его
                        (when (symbol? new)
                           #false ; todo: вызвать функцию (сделай-при-выходе-из-состояния)
                           ((npc 'set) 'state new)
                           #false ; todo: вызвать функцию (сделай-при-входе-в-состояние)
                           )))))))
      (ff->alist (level:get 'npcs)))

   ; draw
   ((unbox renderer) mouse)))

; -- game ----------------------------------
(coroutine 'game (lambda ()
   (let this ((itself #empty))
   (let*((envelope (wait-mail))
         (sender msg envelope))
      (case msg

         (['change-level level-name]
            (print "changing level to " level-name)
            (set-car! renderer changing-level-screen)
            (mail sender 'ok)
            (this itself))
         (else
            (print "logic: unhandled event: " msg)
            (this itself)))))))
