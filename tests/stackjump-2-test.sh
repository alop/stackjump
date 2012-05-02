#!/usr/bin/env roundup

. ./test_helper.sh

check_stackjump_files() {
  TMPDIR=$1
  test -f $TMPDIR/ISO/initrd.gz
  ROOT_HOME="$TMPDIR/initrd/root_skel/root"
  SOLOD="$ROOT_HOME/chef-solo"
  CHFBKD="$SOLOD/cookbooks/chef-server"
  RECIPE="$CHFBKD/recipes/default.rb"
  CHEFSEED="$CHFBKD/files/default/chef-server.seed"
  expr "`head -1 $SOLOD/solo.rb`" : 'file_cache_path "/root/chef-solo"'
  expr "`head -2 $SOLOD/solo.json|tail -1`" : '.*recipe\[chef-server::default\]'
  test "`head -1 $RECIPE`" = "package 'chef-server' do"
  test "`head -3 $RECIPE|tail -1`" = '  response_file "chef-server.seed"'
  expr "`head -1 $CHEFSEED`" : 'chef-server-webui'
  expr "`head -3 $ROOT_HOME/late_command.sh|tail -1`" : 'chmod 700 /root/.ssh'
  test "`head -2 $ROOT_HOME/first_run.sh|tail -1`" = 'apt-get update'
  if [ $2 ] && [ $2 = 'githaz' ]; then
    test "`tail -1 $SOLOD/solo.rb`" = '# stackjump default solo.rb'
    expr "`tail -3 $SOLOD/solo.json|head -1`" : '.*stackjump default solo.json'
    expr "`tail -1 $CHEFSEED`" : '# stackjump default chef-server debconf seed file'
    expr "`tail -1 $ROOT_HOME/late_command.sh`" : "# stackjump default late_command.sh"
    expr "`tail -1 $ROOT_HOME/first_run.sh`" : "# stackjump default first_run.sh"
  else
    expr "`tail -1 $SOLOD/solo.rb`" : 'cookbook_path "/root/chef-solo/cookbooks"'
    test `wc -l $SOLOD/solo.json|awk '{print $1}'` = 3
    expr "`tail -1 $CHEFSEED`" : 'chef-solr chef-solr'
    expr "`tail -1 $ROOT_HOME/late_command.sh`" : "sed -i"
    test "`tail -1 $ROOT_HOME/first_run.sh`" = 'reboot'
  fi
}

it_creates_stackjump_files_when_only_preseed() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  check_stackjump_files $TMPDIR
  teardown $TMPDIR
}

it_creates_stackjump_files_when_github_no_haz() {
  PRESEED=`randomf`
  TMPDIR=`sj -p $PRESEED -g $BADREPO -k|grep Temp|awk '{print $3}'`
  teardown $PRESEED
  check_stackjump_files $TMPDIR
  teardown $TMPDIR
}

it_creates_stackjump_files_when_dir_no_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  check_stackjump_files $TMPDIR
  teardown $TMPDIR
}

it_uses_stackjump_files_when_github_already_haz() {
  TMPDIR=`sj -g $GITREPO -k|grep Temp|awk '{print $3}'`
  check_stackjump_files $TMPDIR githaz
  teardown $TMPDIR
}

it_uses_stackjump_files_when_dir_already_haz() {
  RANDOMD=`randomd`
  touch $RANDOMD/preseed.cfg
  mkdir -p $RANDOMD/root/chef-solo
  RAND_ROOT="$RANDOMD/root"
  for i in chef-solo/solo.json chef-solo/solo.rb late_command.sh first_run.sh; do
    echo "dir_`basename $i`" >> $RAND_ROOT/$i
  done
  TMPDIR=`sj -d $RANDOMD -k|grep Temp|awk '{print $3}'`
  teardown $RANDOMD
  ROOT_HOME="$TMPDIR/initrd/root_skel/root"
  SOLOD="$ROOT_HOME/chef-solo"
  for i in $SOLOD/solo.json $SOLOD/solo.rb $ROOT_HOME/late_command.sh $ROOT_HOME/first_run.sh; do
    test "`wc -l $i|awk '{print $1}'`" = 1
    test `cat $i` = "dir_`basename $i`"
  done
  teardown $TMPDIR
}

it_returns_succesful() {
  PRESEED=`randomf`
  OUT=`sj -p $PRESEED|tail -1`
  teardown $PRESEED
  test "$OUT" = 'custom.iso successfully created'
}

it_accepts_chef_repo_dir() {
  RANDOMF=`randomf`
  RANDOMCD=`randomcr`
  sj -p $RANDOMF -cd $RANDOMCD
  teardown $RANDOMF $RANDOMCD
}

it_errors_chef_repo_dir_not_valid() {
  RANDOMF=`randomf`
  OUT=`sj -p $RANDOMF -cd blah|tail -1`
  test "$OUT" = "blah not a valid dir"
  RANDOMD=`randomd`
  ! OUT=`sj -p $RANDOMF -cd $RANDOMD|tail -1`
  expr "$OUT" : "$RANDOMD invalid dir structure"
  teardown $RANDOMF $RANDOMD
}

it_accepts_chef_repo_github() {
  RANDOMF=`randomf`
  CHEF_REPO='https://github.com/opscode/chef-repo.git'
  sj -p $RANDOMF -cg $CHEF_REPO
  teardown $RANDOMF
}

it_errors_chef_repo_github_not_valid() {
  RANDOMF=`randomf`
  CHEF_REPO='git://github.com/jhtran/stackjump_skeleton.git'
  ! OUT=`sj -p $RANDOMF -cg $CHEF_REPO|tail -1`
  teardown $RANDOMF
  expr "$OUT" : ".* invalid dir structure"
}

it_creates_empty_chef_repo() {
  RANDOMF=`randomf`
  TMPDIR=`sj -p $RANDOMF -k|grep Temp|awk '{print $3}'`
  CHEFREPOD="$TMPDIR/initrd/root_skel/home/ubuntu/chef-repo"
  test -d $CHEFREPOD
  for sdir in $REPOSUBDIRS; do
    test -d $CHEFREPOD/$sdir
  done
  OUT=`(cd $CHEFREPOD; git status)|tail -1`
  expr "$OUT" : 'nothing added to commit but untracked files present'
  teardown $TMPDIR $RANDOMF
}
