# RF Swift: GRC's Qt interface (grc/main.py run_qt) uses `languages` before
# assigning it when locale.getdefaultlocale() finds no language: LC_CTYPE=UTF-8
# (macOS's default) or a C/C.UTF-8 locale, and `gnuradio-companion --qt`
# crashes with UnboundLocalError. Report English then, the one translation GRC
# ships.
import locale
_rfswift_getdefaultlocale = locale.getdefaultlocale
locale.getdefaultlocale = lambda *a: (lambda lc, enc: (lc or "en_US", enc))(*_rfswift_getdefaultlocale(*a))
