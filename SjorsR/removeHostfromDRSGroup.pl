#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
	host => {
		type => "=s",
		variable => "host",
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

my ($host_name, $drsgroup_name, $cluster_name, $host_view, $cluster_view, $drsgroup, $grouphosts,
	$groupSpec, $clusterSpec);

$host_name = Opts::get_option("host");
$drsgroup_name = Opts::get_option("drsgroup");
$cluster_name = Opts::get_option("cluster");

$cluster_view = Vim::find_entity_view(
						view_type => "ClusterComputeResource",
						filter => { 'name' => $cluster_name },
						properties => [ 'name', 'configurationEx' ]);
die "Failed to find cluster '$cluster_name'" unless $cluster_view;

$host_view = Vim::find_entity_view(
						view_type => "HostSystem",
						filter => { 'name' => $host_name },
						properties => [ 'name' ],
						begin_entity => $cluster_view);
die "Failed to find host  '$host_name'" unless $host_view;

# only care about vm drs groups and the specified group name
($drsgroup) = grep { $_->isa("ClusterHostGroup") and
						$_->{'name'} eq $drsgroup_name }
				@{$cluster_view->{'configurationEx'}->{'group'}};

die "Failed to find host DRS group '$drsgroup_name'" unless $drsgroup;

# Add virtual machine to the drs group
$grouphosts = eval { $drsgroup->{'host'} } || [ ];
@$grouphosts = grep { $_ != $host_view->{'mo_ref'}} @$grouphosts;
print join(", ", @grouphosts);

$groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("edit");
$groupSpec->{'info'} = $drsgroup;
$groupSpec->{'info'}->{'vm'} = [ @$grouphosts];

$clusterSpec = new ClusterConfigSpecEx();
$clusterSpec->{'groupSpec'} = [ $groupSpec ];

$cluster_view->ReconfigureComputeResource(spec => $clusterSpec, modify => 1);

Util::disconnect();

BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
