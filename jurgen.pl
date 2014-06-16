#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
	ruletype => {
		type => "=s",
		variable => "ruletype",
		required => 0,
	},
	cluster => {
		type => "=s",
		variable => "cluster",
		required => 1
	},
	vm => {
		type => "=s",
		variable => "vm",
		required => 0
	},
	rulename => {
		type => "=s",
		variable => "rulename",
		required => 0,
	}
);

Opts::add_options(%opts);

Opts::parse();
Opts::validate();
Util::connect();

my ($vm_name, $cluster, $cluster_groups, $ruletype, $rulename, $vms_view, $cluster_view);

$vm_name = Opts::get_option("vm");
$ruletype = Opts::get_option("ruletype");
$rulename = Opts::get_option("rulename");
$cluster = Opts::get_option("cluster");

$cluster_view = Vim::find_entity_view(view_type => 'ClusterComputeResource',
                                          filter => { name => $cluster });

my $rules = $cluster_view->configuration->rule;
print "Key : " . @$rules . "\n";
print "DRS rules cluster: " . $cluster . "\n";
foreach (@$rules) {
        my $rule = $_;
        my $is_enabled = $rule->enabled;
        my $rule_name = $rule->name;
        my $rule_key = $rule->key;
        my $type = ref($rule);
        print "$rule_name\t $is_enabled\t $rule_key\t $type\n";
}
        print "\n";

foreach my $HostInCluster (@{$cluster_view->configurationEx->group}) {

if (ref($HostInCluster) eq "ClusterHostGroup") {
	print "Cluster Host Group: ", $HostInCluster->name, "\n";
	foreach my $HostNames (@{$HostInCluster->host}) {
	my $HostMor = Vim::get_view(mo_ref => $HostNames);
	print $HostMor->summary->config->name, "\n";
                                }
        print "\n"
                         }
}

foreach my $vmsInCluster (@{$cluster_view->configurationEx->group}) {

if (ref($vmsInCluster) eq "ClusterVmGroup") {
	print "Cluster VM Group: ", $vmsInCluster->name, "\n";
	foreach my $vmNames (@{$vmsInCluster->vm}) {
	my $vmMor = Vim::get_view(mo_ref => $vmNames);
	print $vmMor->config->name, "\n";
	print $vmMor->config->key, "\n";
                                }
        print "\n"
                         }
}


Util::disconnect();

BEGIN {
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}
