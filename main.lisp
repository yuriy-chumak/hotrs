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
(gl:SwapBuffers (interact 'opengl ['get 'context])) ; todo: make a function
(glDeleteTextures 1 (list id)) ; и спокойно удалим сплеш текстуру

; ----------------------------------------------------------
; включим для windows VSYNC,
; для linux он включен по умолчанию 
;
(define-library (---)
(export enable-vsync)
(import (scheme core))
(cond-expand
   (Windows
      (import (OpenGL WGL EXT swap_control))
      (begin
         (define (enable-vsync)
            (if WGL_EXT_swap_control
               (wglSwapIntervalEXT 1))))) ; enable vsync
   (else
      (begin
         (define (enable-vsync) #false)))))
(import (---))
(enable-vsync)

;; ; -------------------------------------------------------
;; ; теперь запустим текстовую консольку
;; (import (lib gl console))

;; ; временное окно дебага (покажем fps):
;; (define fps (create-window 70 24 10 1))
;; (define started (time-ms)) (define time '(0))
;; (define frames '(0 . 0))

;; (set-window-writer fps (lambda (print)
;;    (set-car! frames (+ (car frames) 1))
;;    (let ((now (time-ms)))
;;       (if (> now (+ started (car time) 1000))
;;          (begin
;;             (set-cdr! frames (car frames))
;;             (set-car! frames 0)
;;             (set-car! time (- now started)))))
;;    (print GRAY (cdr frames) " fps")
;; ))

; ----------------
; музычка...
;,load "music.lisp" ; временно отключена

;; ; остальные библиотеки (в том числе игровые)
(import (lib keyboard))
;; (import (lib math))
;; (import (otus random!))
;; (import (lang sexp))
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
(define CELL-WIDTH (interact 'level ['get 'tilewidth]))
(define CELL-HEIGHT (interact 'level ['get 'tileheight]))

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

; draw
(define (playing-level-screen mouse)
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
;; ;;             ;;    (interact 'creatures ['get 'skeletons]))
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
               (ff->alist (interact 'level ['get 'npcs])))))

   (level:draw creatures)

   ; окошки, консолька, etc.
   ;; (render-windows)

   ; let's draw mouse pointer
   (glScalef (/ 1 (config 'scale 40)) (/ 1 (config 'scale 40)) 1)
   (if mouse
      (let*(;(ms (mod (floor (/ (time-ms) 100)) 40))
            (viewport '(0 0 0 0))
            (_ (glGetIntegerv GL_VIEWPORT viewport))
            (tile (getf (level:get 'tileset)
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
      (define hero ((interact 'level ['get 'npcs]) 'hero #f))
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
   ; обработчик состояния клавиатуры
   ;  внимание, это "состояние", а не "события"!
   ;  посему можно обрабатывать сразу несколько нажатий клавиатуры одновременно
   (if (key-pressed? KEY_ESC) (halt 1))

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


   ; дебаг-интерфейс, позволяющий двигать окно просмотра по всей карте:
   (if (key-pressed? KEY_RIGHT) (move +0.051 0)) ; right
   (if (key-pressed? KEY_LEFT)  (move -0.051 0)) ; left
   (if (key-pressed? KEY_UP)    (move 0 -0.031)) ; up
   (if (key-pressed? KEY_DOWN)  (move 0 +0.031)) ; down

   (when (key-pressed? KEY_1) ; todo: move hero to new location
      (level:load "floor-1.json"))

   (when (key-pressed? KEY_2) ; todo: move hero to new location
      (level:load "floor-2.json"))

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


;; ;; ; keyboard
;; ;; ; обработчик событий клавиатуры
;; ;; ;  внимание, это "события", а не "состояние"!!!
;; (gl:set-keyboard-handler (lambda (key)
;;    (print "key: " key)))
;;    ;; (case key
;;    ;;    (#x18
;;    ;;       ;(mail 'music ['shutdown])
;;    ;;       (halt 1))))) ; q - quit

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
   ((unbox renderer) mouse)))

; -- game ----------------------------------
(fork-server 'game (lambda ()
   (let this ((itself #empty))
   (let*((envelope (wait-mail))
         (sender msg envelope))
      (case msg

         (['change-level level-name]
            (print "changing level to " level-name)
            (set-car! renderer changing-level-screen)
            (mail sender 'ok)
            (this itself))

;; ;;          (['turn]
;; ;;             (let ((creatures
;; ;;                      (sort (lambda (a b)
;; ;;                               (less? (car a) (car b)))
;; ;;                         (ff->alist (interact 'creatures ['debug])))))
;; ;; ;;             ; 1. Каждому надо выдать некотрое количество action-points (сколько действий он может выполнить за ход)
;; ;; ;;             ;  это, конечно же, зависит от npc - у каждого может быть разное
;; ;; ;;             ; TBD.

;; ;; ;;             ; 2. Отсортировать всех по уровню инициативности, то есть кто имеет право ударить первым
;; ;; ;;             ;  это тоже зависит от npc

;; ;; ;;             ; 3. И только теперь подергать каждого - пусть походит
;; ;; ;;             ;  причем следующего можно дергать только после того, как отработают все запланированные анимации хода
;; ;;             (for-each (lambda (creature)
;; ;;                   (let*((creature (cdr creature))
;; ;;                         (state ((creature 'get) 'state))
;; ;;                         (_ (print "state: " state))
;; ;;                         (state (if state (state creature #false))))
;; ;;                      (if state
;; ;;                         ((creature 'set) 'state state))))
;; ;; ;;                   ; для тестов - пусть каждый скелет получает урон "-50"
;; ;; ;;                   (ai:make-action creature 'damage 50))
;; ;;                creatures)

;; ;;             ; вроде все обработали, можно переходить в состояние "готов к следующему ходу"
;; ;;             (set-car! calculating-world (- (unbox calculating-world) 1))
;; ;;             (this itself)))
;; ;; ;;          ((fire-in-the-tile xy)
;; ;; ;;             (for-each (lambda (creature)
;; ;; ;;                   ; для тестов - пусть каждый скелет получает урон "-50"
;; ;; ;;                   (if (equal? (interact creature ['get 'location]) xy)
;; ;; ;;                      (ai:make-action creature 'damage 50)))
;; ;; ;;                (interact 'creatures ['get 'skeletons]))
;; ;; ;;             (set-car! calculating-world #false)
;; ;; ;;             (this itself))

;;          (['go to]
;;             (print "go to " to)
;;             (let*((creature (interact 'creatures ['get 'hero]))
;;                   (state ((creature 'get) 'state))
;;                   (state (if state (state creature ['go to]))))
;;                (if state
;;                   ((creature 'set) 'state state)))

;;             ; а теперь пускай ходят npc
;;             (let ((creatures
;;                      (sort (lambda (a b)
;;                               (less? a b)) ; todo: отсортировать по инициативности
;;                         (interact 'npcs #false))))
;;                (for-each (lambda (creature)
;;                      (print "NPC: " creature)
;;                      (let*((creature creature)
;;                            (state ((creature 'get) 'state))
;;                            ;; (_ (print "NPC state: " state))
;;                            (state (if state (state creature #false))))
;;                         (if state
;;                            ((creature 'set) 'state state))))
;;                   creatures))

;;             (set-car! calculating-world (- (unbox calculating-world) 1))
;;             (this itself))
         (else
            (print "logic: unhandled event: " msg)
            (this itself)))))))
