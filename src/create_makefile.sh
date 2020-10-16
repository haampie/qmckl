#!/bin/bash

OUTPUT=Makefile.generated

# Tangle org files

emacsclient -a "" \
            --socket-name=org_to_code \
            --eval "(require 'org)"

for INPUT in $@ ; do
    emacsclient \
	--no-wait \
	--socket-name=org_to_code \
     	--eval "(org-babel-tangle-file \"$INPUT\")"
done

emacsclient \
    --no-wait \
    --socket-name=org_to_code \
    --eval '(kill-emacs)'



# Create the list of *.o files to be created

OBJECTS=""
for i in $(ls qmckl_*.c) ; do
    FILE=${i%.c}
    OBJECTS="${OBJECTS} ${FILE}.o"
done >> $OUTPUT

for i in $(ls qmckl_*.f90) ; do
    FILE=${i%.f90}
    OBJECTS="${OBJECTS} ${FILE}.o"
done >> $OUTPUT

TESTS=""
for i in $(ls test_*.c) ; do
    FILE=${i%.c}
    TESTS="${TESTS} ${FILE}"
done >> $OUTPUT


# Write the Makefile

cat << EOF > $OUTPUT
CC=$CC
CFLAGS=$CFLAGS

FC=$FC
FFLAGS=$FFLAGS
OBJECT_FILES=$OBJECTS
TESTS=$TESTS

libqmckl.so: \$(OBJECT_FILES)
	\$(CC) -shared \$(OBJECT_FILES) -o libqmckl.so

%.o: %.c 
	\$(CC) \$(CFLAGS) -c \$*.c -o \$*.o

%.o: %.f90 
	\$(FC) \$(FFLAGS) -c \$*.f90 -o \$*.o

test_%: test_%.c 
	\$(CC) \$(CFLAGS) -Wl,-rpath,$PWD -L. \
        -I../munit/ ../munit/munit.c test_\$*.c -lqmckl -o test_\$*

test: libqmckl.so \$(TESTS)
	for i in \$(TESTS) ; do ./\$\$i ; done

.PHONY: test
EOF

for i in $(ls qmckl_*.c) ; do
    FILE=${i%.c}
    echo "${FILE}.o: ${FILE}.c " *.h
done >> $OUTPUT

for i in $(ls qmckl_*.f90) ; do
    FILE=${i%.f90}
    echo "${FILE}.o: ${FILE}.f90"
done >> $OUTPUT

