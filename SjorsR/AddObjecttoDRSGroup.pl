#!/usr/bin/perl
## Adds an object to a vSphere DRS Group. If the group doesn't exist, create it.
use strict;
use warnings;

use VMware::VIRuntime;

#Script options
my %opts = (
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

my ($drsgroup_name, $cluster_name, , $cluster_view,
  $groupSpec, $clusterSpec,$drsgroup_type, $drs_object);

#drsgroup_type is the type of DRS group. VirtualMachine or HostSystem
#drsgroup_name is the DRS group name.
#cluster_name is the vSphere cluster name
#drs_object is the object to add to the DRS group.

$drsgroup_name = Opts::get_option("drsgroup");
$cluster_name = Opts::get_option("cluster");
$drsgroup_type = Opts::get_option("drsgroup_type");
$drs_object = Opts::get_option("drs_object");

$cluster_view = Vim::find_entity_view(
        view_type => "ClusterComputeResource",
        filter => { 'name' => $cluster_name },
        properties => [ 'name', 'configurationEx' ]);
unless $cluster_view {
  Util::disconnect();
  die "Failed to find cluster '$cluster_name'"

}





my $objects = Vim::find_entity_views(
                                view_type => "VirtualMachine",
                                filter => { 'name' => $drs_object });

#my $groupSpec = new ClusterGroupSpec();
#$groupSpec->{'operation'} = new ArrayUpdateOperation("add");
#$groupSpec->{'info'} = new ClusterGroupInfo(name=>"objgroup")$drsgroup;


$groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("add");
$groupSpec->{'info'} = new ClusterGroupInfo(name=>"drsgroup_name");
$groupSpec->{'info'}->{vm} = $objects
$groupSpec->{'name'} = $drsgroup_name;
#print "GroupSpec : " . $clu_spec . "\n";
#
#$clusterSpec = new ClusterConfigSpecEx();
#$clusterSpec->{'operation'} = new ArrayUpdateOperation("edit");
#$clusterSpec->{'groupSpec'} = [ $groupSpec ];

#$cluster_view->ReconfigureComputeResource(spec => $clusterSpec, modify => 1);
$cluster_view->ReconfigureComputeResource(spec => $clu_spec, modify => 1);
print "cluster_view : " . $cluster_view . "\n";

Util::disconnect();

BEGIN {
  $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}




$cluster_view = Vim::find_entity_view(
            view_type => "ClusterComputeResource",
            filter => { 'name' => $cluster_name },
            properties => [ 'name', 'configurationEx' ]);
die "Failed to find cluster '$cluster_name'" unless $cluster_view;

$vm_view = Vim::find_entity_view(
            view_type => "VirtualMachine",
            filter => { 'name' => $vm_name },
            properties => [ 'name' ],
            begin_entity => $cluster_view);
die "Failed to find virtual machine '$vm_name'" unless $vm_view;

# only care about vm drs groups and the specified group name
($drsgroup) = grep { $_->isa("ClusterVmGroup") and
            $_->{'name'} eq $drsgroup_name }
        @{$cluster_view->{'configurationEx'}->{'group'}};

die "Failed to find virtual machine DRS group '$drsgroup_name'" unless $drsgroup;

# Add virtual machine to the drs group
$groupvms = eval { $drsgroup->{'vm'} } || [ ];
push @$groupvms, $vm_view->{'mo_ref'};

$groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("edit");
$groupSpec->{'info'} = $drsgroup;
$groupSpec->{'info'}->{'vm'} = [ @$groupvms ];

$clusterSpec = new ClusterConfigSpecEx();
$clusterSpec->{'groupSpec'} = [ $groupSpec ];

$cluster_view->ReconfigureComputeResource(spec => $clusterSpec, modify => 1);

Util::disconnect();

BEGIN {
  $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
