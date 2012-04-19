#!/usr/local/bin/roundup

PATH="$PATH:.."
alias sj="stackjump -t "

randomn() {
  echo "/tmp/`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 10| head -n 1`"
}
randomf() {
  RANDOM=`randomn`
  echo "preseed_file" > $RANDOM
  echo $RANDOM
}
randomd() {
  RANDOM=`randomn`
  mkdir $RANDOM
  echo "preseed_dir" > $RANDOM/preseed.cfg
  echo $RANDOM
}

teardown() {
  for i in $@; do
    if [ -d $i ]; then
      if [ `expr "$i" : '/tmp'` ]; then  
        rm -rf $i
      fi
    elif [ -f $i ]; then
      if [ `expr "$i" : '/tmp'` ]; then  
        rm -f $i
      fi
    fi
  done
  if [ -f custom.iso ]; then
    rm -f custom.iso
  fi
}

it_reqs_args() {
  ! sj
}

it_displays_usage() {
  OUT=`sj|head -2|tail -1`
  expr "$OUT" : '  -p preseed'
}

it_needs_real_preseed() {
  RANDOM=`randomn`
  ! OUT=`sj -p $RANDOM`
  test "$OUT" = "$RANDOM not a valid preseed file"
}

it_not_allow_dir_and_git() {
  ! OUT=`sj -d /tmp -g git@github.com/user/proj`
  test "$OUT" = 'Use only one of the -d or -g flags.'
}

it_checks_real_dir() {
  RANDOM=`randomn`
  ! OUT=`sj -d $RANDOM`
  test "$OUT" = "Directory $RANDOM invalid"
}

it_checks_dir_has_preseed() {
  RANDOM=`randomn`
  mkdir -p $RANDOM
  ! OUT=`sj -d $RANDOM`
  test "$OUT" = "$RANDOM/preseed.cfg doesn't exist"
  teardown $RANDOM
}

it_warns_preseed_overrides() {
  RANDOMD=`randomd`
  RANDOMF=`randomf`
  OUT=`sj -d $RANDOMD -p $RANDOMF|grep Warning`
  teardown $RANDOMD $RANDOMF
  test "$OUT" = "Warning: $RANDOMD contains a preseed.cfg but -p $RANDOMF takes precedence"
}

it_uses_preseed_arg_over_dir() {
  RANDOMD=`randomd`
  RANDOMF=`randomf`
  TMPDIR=`sj -d $RANDOMD -p $RANDOMF -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD $RANDOMF
  test `cat $TMPDIR/initrd/preseed.cfg` = 'preseed_file'
  teardown $TMPDIR
}

it_defaults_custom_iso() {
  PRESEED=`randomf`
  sj -p $PRESEED
  test -f custom.iso
  teardown $PRESEED
}

it_outputs_mynamed_iso() {
  PRESEED=`randomf`
  sj -p $PRESEED -o mynamed.iso
  test -f mynamed.iso
  test ! -f custom.iso
  teardown $PRESEED
}

it_arch_amd64() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -a amd64 -k|grep Temp|awk '{print $3}'`
  TESTUB=`cat $TMPDIR/testub|head -1`
  expr "$TESTUB" : '.*\/ubuntu-installer\/amd64'
  teardown $PRESEED $TMPDIR
}

it_arch_i386() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -a i386 -k|grep Temp|awk '{print $3}'`
  TESTUB=`cat $TMPDIR/testub|head -1`
  expr "$TESTUB" : '.*\/ubuntu-installer\/i386'
  teardown $PRESEED $TMPDIR
}

it_complains_invalid_arch() {
  PRESEED=`randomf`
  ! OUT=`sj -p $PRESEED -a amd99`
  test "$OUT" = "Architecture amd99 is not valid.  (amd64|i386)"
  teardown $PRESEED
}
