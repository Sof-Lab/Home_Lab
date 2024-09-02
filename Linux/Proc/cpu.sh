#!/bin/bash

# Create file for tests
if ! [ -f "test.jpg" ]; then
	fallocate -l 500M test.jpg;
fi

# Processes whis different nice priority
# Please, uncomment one of this line
#time nice -n 10 tar -cf tar.gz test.jpg & time nice -n 10 tar -cf tar2.gz test.jpg &
#time nice -n -20 tar -cf tar.gz test.jpg & time nice -n 19 tar -cf tar2.gz test.jpg &

wait
rm tar.gz
rm tar2.gz