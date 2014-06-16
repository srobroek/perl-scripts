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

my ($drsgroup_name, $cluster_name, $cluster_view, $drsgroup, $Spec, 
        $groupSpec, $clusterSpec);


$drsgroup_name = Opts::get_option("drsgroup");
print "DRS group Name: " . $drsgroup_name . "\n";
$cluster_name = Opts::get_option("cluster");
print "Cluster Name: " . $cluster_name . "\n";
$cluster_view = Vim::find_entity_view(
                                                view_type => "ClusterComputeResource",
                                                filter => { 'name' => $cluster_name },
                                                properties => [ 'name', 'configurationEx' ]);
print "Cluster View: " . $cluster_view . "\n";
die "Failed to find cluster '$cluster_name'" unless $cluster_view;


# only care about vm drs groups and the specified group name
#($drsgroup) = grep { $_->isa("ClusterVmGroup") and
#                                                $_->{'name'} eq $drsgroup_name }
#                                @{$cluster_view->{'configurationEx'}->{'group'}};
#
#die "Failed to find virtual machine DRS group '$drsgroup_name'" unless $drsgroup;


$Spec = new ClusterConfigSpecEx();

$groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("remove");
$groupSpec->{'info'} = $drsgroup;
$groupSpec->{'RemoveKey'} = $drsgroup_name;
$Spec ->{'groupSpec'} = $groupSpec;

$cluster_name->ReconfigureComputeResource(spec => $Spec, modify => 1);

Util::disconnect();

BEGIN {
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
