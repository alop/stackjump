#!/usr/bin/env roundup

. ./test_helper.sh

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

it_uses_valid_dir_preseed() {
  RANDOMD=`randomd`
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  test `cat $TMPDIR/initrd/preseed.cfg` = 'preseed_dir'
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
  rm -f mynamed.iso
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

it_complains_invalid_release_codename() {
  PRESEED=`randomf`
  ! OUT=`sj -p $PRESEED -r batty`
  expr "$OUT" : 'Release batty invalid'
  teardown $PRESEED
}

it_allows_valid_ubuntu_release_other_than_natty() {
  PRESEED=`randomf`
  sj -p $PRESEED -r precise
  teardown $PRESEED
}

it_complains_github_url_bad() {
  ! sj -g blah@somebadgit.com
  ! sj -g blah@github.com
  ! sj -g blah@github.com/user/proj.git
  ! sj -g blah@github.com:user/proj.git
}

it_allows_valid_github_repo() {
  sj -g $GITREPO
}

it_complains_github_repo_no_preseed() {
  ! OUT=`sj -g $GITURL/BAD_skeleton.git|grep exist`
  expr "$OUT" : '.*preseed.cfg doesn.t exist'
}

it_warns_preseed_overrides_github() {
  RANDOMF=`randomf`
  OUT=`sj -g $GITREPO -p $RANDOMF|grep Warning`
  teardown $RANDOMF
  test "$OUT" = "Warning: $GITREPO contains a preseed.cfg but -p $RANDOMF takes precedence"
}

it_uses_preseed_arg_over_github() {
  RANDOMF=`randomf`
  TMPDIR=`sj -g $GITREPO -p $RANDOMF -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMF
  test `cat $TMPDIR/initrd/preseed.cfg` = 'preseed_file'
  teardown $TMPDIR
}

it_uses_valid_github_preseed() {
  TMPDIR=`sj -g $GITREPO -k|grep Temp|awk '{print $3}'`
  expr "`head -2 $TMPDIR/initrd/preseed.cfg|tail -1`" : '.*debian-installer\/locale'
  teardown $TMPDIR
}

it_creates_isolinux_cfg_when_only_preseed() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  test -f $TMPDIR/ISO/isolinux.cfg
  expr "`head -1 $TMPDIR/ISO/isolinux.cfg`" : 'prompt 0'
  expr "`tail -1 $TMPDIR/ISO/isolinux.cfg`" : 'append auto ramdisk'
  teardown $TMPDIR
}

it_creates_isolinux_cfg_when_dir() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  test ! -f "$RANDOMD/ISO/isolinux.cfg"
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  test -f $TMPDIR/ISO/isolinux.cfg
  expr "`head -1 $TMPDIR/ISO/isolinux.cfg`" : 'prompt 0'
  expr "`tail -1 $TMPDIR/ISO/isolinux.cfg`" : 'append auto ramdisk'
  teardown $TMPDIR
}

it_creates_isolinux_cfg_when_github() {
  TMPDIR=`sj -g $GITREPO -k|grep Temp|awk '{print $3}'`
  test -f $TMPDIR/ISO/isolinux.cfg
  expr "`head -1 $TMPDIR/ISO/isolinux.cfg`" : 'prompt 0'
  expr "`tail -1 $TMPDIR/ISO/isolinux.cfg`" : 'append auto ramdisk'
  teardown $TMPDIR
}

it_creates_chef_solo_rb_when_only_preseed() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  test -f $TMPDIR/$SOLOPATH/solo.rb
  expr "`head -1 $TMPDIR/$SOLOPATH/solo.rb`" : 'file_cache_path "/root/chef-solo"'
  expr "`tail -1 $TMPDIR/$SOLOPATH/solo.rb`" : 'cookbook_path "/root/chef-solo/cookbooks"'
  teardown $TMPDIR
}

it_creates_chef_solo_rb_when_dir_no_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  test -f $TMPDIR/$SOLOPATH/solo.rb
  expr "`head -1 $TMPDIR/$SOLOPATH/solo.rb`" : 'file_cache_path "/root/chef-solo"'
  expr "`tail -1 $TMPDIR/$SOLOPATH/solo.rb`" : 'cookbook_path "/root/chef-solo/cookbooks"'
  teardown $TMPDIR
}

it_creates_chef_solo_rb_when_github_no_haz() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -g $BADREPO -k|grep Temp|awk '{print $3}'`
  test -f $TMPDIR/$SOLOPATH/solo.rb
  expr "`head -1 $TMPDIR/$SOLOPATH/solo.rb`" : 'file_cache_path "/root/chef-solo"'
  expr "`tail -1 $TMPDIR/$SOLOPATH/solo.rb`" : 'cookbook_path "/root/chef-solo/cookbooks"'
  teardown $TMPDIR
}

it_creates_chef_solo_json_when_only_preseed() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  test -f $TMPDIR/$SOLOPATH/solo.json
  test `wc -l $TMPDIR/$SOLOPATH/solo.json|awk '{print $1}'` = 3
  test "`head -2 $TMPDIR/$SOLOPATH/solo.json|tail -1`" = '  "run_list": [ "recipe[chef-server::default]" ]'
  teardown $TMPDIR
}

it_creates_chef_solo_json_when_dir_no_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  test -f $TMPDIR/$SOLOPATH/solo.json
  test `wc -l $TMPDIR/$SOLOPATH/solo.json|awk '{print $1}'` = 3
  test "`head -2 $TMPDIR/$SOLOPATH/solo.json|tail -1`" = '  "run_list": [ "recipe[chef-server::default]" ]'
  teardown $TMPDIR
}

it_creates_chef_solo_json_when_github_no_haz() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -g $BADREPO -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  test -f $TMPDIR/$SOLOPATH/solo.json
  test `wc -l $TMPDIR/$SOLOPATH/solo.json|awk '{print $1}'` = 3
  test "`head -2 $TMPDIR/$SOLOPATH/solo.json|tail -1`" = '  "run_list": [ "recipe[chef-server::default]" ]'
  teardown $TMPDIR
}
