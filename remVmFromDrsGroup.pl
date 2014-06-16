#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
        cluster => {
                type => "=s",
                variable => "cluster",
                required => 1,
        },
        drsgroup => {
                type => "=s",
                variable => "drsgroup",
                required => 1,
        },
        ruleset => {
                type => "=s",
                variable => "ruleset",
                required => 1,
        },
);

Opts::add_options(%opts);

Opts::parse();
Opts::validate();
Util::connect();

my ($drsgroup_name, $cluster_name, $cluster_view, $drsgroup, $Spec, 
        $groupSpec, $clusterSpec, $ruleset_name, $rules);


$drsgroup_name = Opts::get_option("drsgroup");
print "DRS group Name: " . $drsgroup_name . "\n";
$cluster_name = Opts::get_option("cluster");
print "Cluster Name: " . $cluster_name . "\n";
$ruleset_name = Opts::get_option("ruleset");
print "Ruleset Name: " . $ruleset_name . "\n";

#
$cluster_view = Vim::find_entity_view(
                                                view_type => "ClusterComputeResource",
                                                filter => { 'name' => $cluster_name },
                                                properties => [ 'name', 'configurationEx' ]);
die "Failed to find cluster '$cluster_name'" unless $cluster_view;


my $test = grep { $_->isa("ClusterVmGroup")};
print "var: " . $test . "\n";
# only care about vm drs groups and the specified group name
($drsgroup) = grep { $_->isa("ClusterVmGroup") and
                                                $_->{'name'} eq $drsgroup_name }
                                @{$cluster_view->{'configurationEx'}->{'group'}};

die "Failed to find virtual machine DRS group '$drsgroup_name'" unless $drsgroup;

#
print "var: " . $_->isa("ClusterRuleInfo") . "\n";
($rules) = grep { $_->isa("ClusterRuleInfo") and
                                                $_->{'name'} eq $ruleset_name }
                                @{$cluster_view->{'configurationEx'}->{'rule'}};
print "Cluster Rule: " . $rules->name . "\n";


$groupSpec = new ClusterGroupSpec();
$groupSpec->{'operation'} = new ArrayUpdateOperation("remove");
$groupSpec->{'info'} = $drsgroup;
$groupSpec->{'RemoveKey'} = $drsgroup_name;

$clusterSpec = new ClusterConfigSpecEx();
$clusterSpec->{'groupSpec'} = [ $groupSpec ];
print "drgroup: " . $drsgroup . "\n";

$cluster_name->ReconfigureComputeResource(spec => $clusterSpec,modify => 'true');

Util::disconnect();

BEGIN {
        $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
