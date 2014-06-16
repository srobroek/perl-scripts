#!/usr/bin/perl

use strict;
use warnings;

use VMware::VIRuntime;
my %opts = (
        cluster => {
                type => "=s",
                variable => "cluster",
                required => 1,
        }
);

Opts::add_options(%opts);

Opts::parse();
Opts::validate();
Util::connect();

my $cluster_name = Opts::get_option("cluster");

my $cluster_view = Vim::find_entity_view(
               view_type => "ClusterComputeResource",
               filter => { 'name' => $cluster_name });

foreach my $vmsInCluster (@{$cluster_view->configurationEx->group}) {
          if (ref($vmsInCluster) eq "ClusterVmGroup") {
          print "DRS group name: ", $vmsInCluster->name, "\n";
             foreach my $vmNames (@{$vmsInCluster->vm}) {
               my $vmMor = Vim::get_view(mo_ref => $vmNames);
                  print $vmMor->config->name, "\n";
             }
          }
}
