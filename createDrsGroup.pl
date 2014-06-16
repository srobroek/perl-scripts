#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

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

my ($drsgroup_name, $cluster_name, $vm_view, $cluster_view, $drsgroup, $groupvms,
	$groupSpec, $clusterSpec);

$drsgroup_name = Opts::get_option("drsgroup");
$cluster_name = Opts::get_option("cluster");

$cluster_view = Vim::find_entity_view(
				view_type => "ClusterComputeResource",
				filter => { 'name' => $cluster_name },
				properties => [ 'name', 'configurationEx' ]);
die "Failed to find cluster '$cluster_name'" unless $cluster_view;

my $grp_conf = ClusterGroupInfo->new(
        name => "$drsgroup_name"
);

my $clu_spec = ClusterConfigSpecEx->new(
        groupSpec => $grp_conf
);

#$groupSpec = new ClusterGroupSpec();
#$groupSpec->{'operation'} = new ArrayUpdateOperation("add");
#$groupSpec->{'info'} = $cluster_name;
#$groupSpec->{'name'} = $drsgroup_name;
print "GroupSpec : " . $clu_spec . "\n";
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
