#!/bin/bash

# Create files for tests
if ! [ -f "test.txt" ]; then
	dd if=/dev/zero of=test.txt  bs=1G  count=1
	cp test.txt test2.txt
	sync; echo 1 > /proc/sys/vm/drop_caches;
fi

# Processes whis different ionice priority
# Please, uncomment one of this line
#time ionice -c2 -n0 cp test.txt test_tmp.txt & time ionice -c2 -n0 cp test2.txt test2_tmp.txt &
#time ionice -c1 -n0 cp test.txt test_tmp.txt & time ionice -c3 cp test2.txt test2_tmp.txt &
#time ionice -c1 -n0 cp test.txt test_tmp.txt & time ionice -c2 -n7 cp test2.txt test2_tmp.txt &
#time ionice -c2 -n0 cp test.txt test_tmp.txt & time ionice -c2 -n7 cp test2.txt test2_tmp.txt &

wait
rm test_tmp.txt
rm test2_tmp.txt

# Clean cache 
sync; echo 1 > /proc/sys/vm/drop_caches