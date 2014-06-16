#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
  vm => {
    type => "=s",
    variable => "object",
    required => 1,
  },
  cluster => {
    type => "=s",
    variable => "cluster",
    required => 1
  },
  drsgroup => {
    type => "=s",
    variable => "drsgroup",
    required => 1,
  }
);

Opts::add_options(%opts);

Opts::parse();
Opts::validate();
Util::connect();

my ($object_name, $drsgroup_name, $cluster_name, $object_view, $cluster_view, $drsgroup, $groupvms,
  $groupSpec, $clusterSpec,$objecttype);

my $vm_name = Opts::get_option("object");
my $drsgroup_name = Opts::get_option("drsgroup");
my $cluster_name = Opts::get_option("cluster");

my $cluster_view = Vim::find_entity_view(
            view_type => "ClusterComputeResource",
            filter => { 'name' => $cluster_name },
            properties => [ 'name', 'configurationEx' ]);
die "Failed to find cluster '$cluster_name'" unless $cluster_view;

my $obj_view = Vim::find_entity_view(
            view_type => $objecttype,
            filter => { 'name' => $object_name },
            properties => [ 'name' ],
            begin_entity => $cluster_view);
die "Failed to find object '$object'" unless $object_view;

# only care about vm drs groups and the specified group name
($drsgroup) = grep { $_->isa("ClusterVmGroup") and
            $_->{'name'} eq $drsgroup_name }
        @{$cluster_view->{'configurationEx'}->{'group'}};

die "Failed to find virtual machine DRS group '$drsgroup_name'" unless $drsgroup;

# Add virtual machine to the drs group
my $groupvms = eval { $drsgroup->{'object'} } || [ ];
push @$groupvms, $vm_view->{'mo_ref'};
print "group: " . $drsgroup->name . "\n";

my $groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("edit");
$groupSpec->{'info'}->{'vm'} = [ @$groupvms ];

my $clusterSpec = new ClusterConfigSpecEx();
$clusterSpec->{'groupSpec'} = [ $groupSpec ];

$cluster_view->ReconfigureComputeResource(spec => $clusterSpec, modify => 1);

Util::disconnect();

BEGIN {
  $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
