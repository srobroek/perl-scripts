#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
	vm => {
		type => "=s",
		variable => "vm",
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

my ($vm_name, $drsgroup_name, $cluster_name, $vm_view, $cluster_view, $drsgroup, $groupvms,
	$groupSpec, $clusterSpec);

$vm_name = Opts::get_option("vm");
$drsgroup_name = Opts::get_option("drsgroup");
$cluster_name = Opts::get_option("cluster");

$cluster_view = Vim::find_entity_view(
						view_type => "ClusterComputeResource",
						filter => { 'name' => $cluster_name },
						properties => [ 'name', 'configurationEx' ]);
die "Failed to find cluster '$cluster_name'" unless $cluster_view;

$vm_view = Vim::find_entity_view(
						view_type => "VirtualMachine",
						filter => { 'name' => $vm_name },
						#properties => [ 'name' ],
						begin_entity => $cluster_view);
die "Failed to find virtual machine '$vm_name'" unless $vm_view;

# only care about vm drs groups and the specified group name
($drsgroup) = grep { $_->isa("ClusterVmGroup") and
						$_->{'name'} eq $drsgroup_name }
				@{$cluster_view->{'configurationEx'}->{'group'}};

die "Failed to find virtual machine DRS group '$drsgroup_name'" unless $drsgroup;

# Add virtual machine to the drs group
$groupvms = eval { $drsgroup->{'vm'} } || [ ];

@$groupvms = grep { $_ != $vm_view->{'mo_ref'}}  @$groupvms;
my $index=0;
foreach (@$groupvms) {
	$index++;
	if $_ == $vm_view-{'mo_ref'} (
	last;
	)
}
print $index, "\n";
@$groupvms = splice (@$groupvms, $index, 1);
#print "\nVMVIEW:".$vm_view->{'mo_ref'};

$groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("edit");
$groupSpec->{'info'} = $drsgroup;
$groupSpec->{'info'}->{'host'} = [ @$groupvms ];

$clusterSpec = new ClusterConfigSpecEx();
$clusterSpec->{'groupSpec'} = [ $groupSpec ];

$cluster_view->ReconfigureComputeResource(spec => $clusterSpec, modify => 1);

Util::disconnect();

BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
