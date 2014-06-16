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
        vmgroup => {
                type => "=s",
                variable => "vmgroup",
                required => 1,
        },
	esxgroup => {
                type => "=s",
                variable => "esxgroup",
                required => 0,
        },
	rule => {
                type => "=s",
                variable => "ruleset",
                required => 0,
        },
	vm => {
                type => "=s",
                variable => "vm",
                required => 0,
        },
);

Opts::add_options(%opts);

Opts::parse();
Opts::validate();
Util::connect();

my $cluster = Opts::get_option("cluster");
my $vmgroup = Opts::get_option("vmgroup");
my $vm_name = Opts::get_option("vm");

my $cluster_view = Vim::find_entity_view(
                                view_type => "ClusterComputeResource",
                                filter => { 'name' => $cluster });
unless ($cluster_view){
        Util::disconnect();
        die "No cluster found with name $cluster\n";
}
my $vms = Vim::find_entity_views(
				view_type => "VirtualMachine",
				filter => { 'name' => $vm_name });
unless ($vms){
        Util::disconnect();
        die "No virtual machine found with name $vms\n";
}

my $groupSpec = new ClusterGroupSpec();
$groupSpec->{operation} = new ArrayUpdateOperation("add");
$groupSpec->{info} = new ClusterGroupInfo(name => $vmgroup);
$groupSpec->{info}->{vm} = [$vms];

my $spec = new ClusterConfigSpecEx ();
$spec->{'groupSpec'} = [$groupSpec];

$cluster_view->ReconfigureComputeResource(spec => $spec, modify => 1);

foreach my $vmsInCluster (@{$cluster_view->configurationEx->group}) {
          if (ref($vmsInCluster) eq "ClusterVmGroup") {
          print "DRS rule name is: ", $vmsInCluster->name, "\n";
             foreach my $vmNames (@{$vmsInCluster->vm}) {
               my $vmMor = Vim::get_view(mo_ref => $vmNames);
                  print $vmMor->config->name, "\n";
             }
          }
}

