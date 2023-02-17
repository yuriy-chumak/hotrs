#!/usr/bin/ol

;; THIS IS COMPLETELY A DRAFT CODE!!!
;; just to demonstrate some code techniques

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

; -=( main )=-------------------------------------
; подключаем графические библиотеки, создаем окно
(import (lib gl-2))
(gl:set-window-title "The House of the Rising Sun")
(import (otus ffi))
(import (lib soil))

; -=( сразу нарисуем сплеш )=---------------------
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
(gl:redisplay)
(glDeleteTextures 1 (list id)) ; и спокойно удалим сплеш текстуру

; -------------------------------------------------------
; будем скипать целое количество секунд (не расчитываем аж на такие большие лаги)
(define timestamp (box (cdr (syscall 96))))


; остальные библиотеки (в том числе игровые)
(import (lib keyboard))
(import (otus random!))

; -=( nani )=------------------------
,load "nani/creature.lisp"
,load "nani/level.lisp"
,load "nani/ai.lisp" ; should go after level and creature

; ============================================================================
; 1. Загрузим первый игровой уровень
(level:load "room-22.json")

(define CELL-WIDTH (await (mail 'level ['get 'tilewidth])))
(define CELL-HEIGHT (await (mail 'level ['get 'tileheight])))

(define window [0 0 854 480])

(define (move-window dx dy) ; сдвинуть окно
   (set-ref! window 1 (+ (ref window 1) (floor dx)))
   (set-ref! window 2 (- (ref window 2) (floor dy)))
   (set-ref! window 3 (+ (ref window 3) (floor dx)))
   (set-ref! window 4 (- (ref window 4) (floor dy))))


; init
(glShadeModel GL_SMOOTH)
(glBlendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA)
(gl:hide-cursor)

; -----------------------------------------------------------------------------------------------

; попробуем создать стейт-машину одного нпс (для примера пусть он просто бегает по карте)
; будем гонять перса alister

; живи!
(define alister ((await (mail 'level ['get 'npcs])) 'alister))
(print "alister: " alister)
((alister 'set) 'state-machine (await (mail 'ai "hunter"))) ; todo: rename to soul? ))
((alister 'set) 'gotcha (lambda () #|(set-car! gathered (+ (car gathered) 1))|# #f))

(define bambi ((await (mail 'level ['get 'npcs])) 'bambi))
(print "bambi: " bambi)
((bambi 'set) 'state-machine (await (mail 'ai "hunter"))) ; todo: rename to soul? ))
((bambi 'set) 'gotcha (lambda () #|(set-cdr! gathered (+ (cdr gathered) 1))|# #f))

; -----------------------------------------------------------------------------------------------
; draw
(define (playing-level-screen mouse)
   (define delta ; in usec (microseconds)
      (let*((us (cdr (syscall 96)))) ; мы не ожидаем задержку больше чем 1 секунда
         (define delta (mod (+ (- us (unbox timestamp)) 1000000) 1000000))
         (set-car! timestamp us)
         delta))

   ; теперь можем и порисовать: очистим окно и подготовим оконную математику
   (glClearColor 0.2 0.2 0.2 1)
   (glClear GL_COLOR_BUFFER_BIT)
   (glLoadIdentity)
   (glOrtho (ref window 1) (ref window 3) (ref window 4) (ref window 2) -1 1)

   ; зададим пропорциональное увеличение
   (glScalef (config 'scale 40) (config 'scale 40) 1)

   (glEnable GL_TEXTURE_2D)
   (glEnable GL_BLEND)

   (define npcs (await (mail 'level ['get 'npcs])))

   ; теперь попросим уровень отрисовать себя
   ; (герой входит в общий список npc)
   (define creatures
      (map (lambda (creature)
            (define npc (cdr creature))
            [ ((npc 'get-location))
              ((npc 'get-animation-frame))])
         ; отсортируем npc снизу вверх (по положению на карте)
         (sort (lambda (a b)
                  (< (cdr (((cdr a) 'get-location)))
                     (cdr (((cdr b) 'get-location)))))
               (ff->alist npcs))))

   (level:draw creatures)

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
   (define hero (npcs 'hero))

   ; ----- порталы -----------------------------
   (let*((location ((hero 'get-location)))
         (hx hy (uncons location #f))
         (portals (ff->alist (level:get 'portals))))
      (for-each (lambda (portal)
            ;(print "testing portal " portal)
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
                     (print "loaded")

                     ; move hero to loaded level:
                     (level:set 'npcs
                        (put (level:get 'npcs) 'hero hero))

                     (define spawn (getf (level:get 'spawns) (cdr target)))
                     (print "spawn: " spawn)
                     ((hero 'set-location) (cons (spawn 'x) (+ (spawn 'y) (spawn 'height)))) )
               )))
         (map cdr portals)))


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
   (if (key-pressed? KEY_RIGHT) (move   (*    0.00000392 delta) 0)) ; right +0.051
   (if (key-pressed? KEY_LEFT)  (move   (- (* 0.00000392 delta)) 0)) ; left +0.051
   (if (key-pressed? KEY_UP)    (move 0 (- (* 0.00000238 delta)))) ; up
   (if (key-pressed? KEY_DOWN)  (move 0 (*    0.00000238 delta))) ; down
)

;; ; keyboard
(gl:set-keyboard-handler (lambda (key)
   (print "key: " key)

   #t
))

(define (changing-level-screen mouse)
   ; nothing
   (if (key-pressed? KEY_ESC) (halt 1))
   #false)

(define renderer (box playing-level-screen))
(gl:set-renderer (lambda (mouse)
   ; draw
   ((unbox renderer) mouse)))

; -- game ----------------------------------
(coroutine 'game (lambda ()
   (let this ((itself {}))
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
