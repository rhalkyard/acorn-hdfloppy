DIM code 50*1024

SYS "OS_Module", 18, "ADFS" TO ,,, code%
OSCLI "Save ADFS "+STR$~code%+" +"+STR$~(code%!-4)
OSCLI "Settype ADFS Module"

