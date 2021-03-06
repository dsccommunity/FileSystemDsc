# Localized resources for Folder

ConvertFrom-StringData @'
    GetCurrentState = Getting the current state of the access rules for the identity '{0}' for the path '{1}'. (FSAR0001)
    PathDoesNotExist = Unable to evaluate the access rules for the path '{0}' because the path does not exist. (FSAR0002)
    EvaluatingIfCluster = Could not find the path on the node. Evaluating if the node belongs to a Windows Server Failover Cluster and if the path belongs to a cluster disk partition. (FSAR0003)
    NodeIsClusterMember = The node '{0}' is a member of the Windows Server Failover Cluster '{1}'. Evaluating cluster disk partitions. (FSAR0004)
    EvaluatingOwnerOfClusterDiskPartition = Found a cluster disk partition with the mount point '{0}'. Evaluating if the node '{1}' is a possible owner. (FSAR0005)
    PossibleClusterResourceOwner = The node '{0}' is a possible owner for the path '{1}' but it is currently not the active node. (FSAR0006)
    NotPossibleClusterResourceOwner = The node '{0}' is not a possible owner for the path '{1}'. (FSAR0007)
    NoClusterDiskPartitionFound = No cluster disk partition was found that the path '{0}' could belong to. (FSAR0008)
    NodeIsNotClusterMember = Node does not belong to a Windows Server Failover Cluster. (FSAR0009)
    PathExist = Found the path on the node. Evaluating access rules for identity '{0}'. (FSAR0010)
    IsNotActiveNode = The node '{0}' is not actively hosting the path '{1}'. Exiting the test. (FSAR0011)
    AbsentRightsNotInDesiredState = The identity '{0}' has the rights '{1}', but expected the identity to have no rights. (FSAR0012)
    InDesiredState = The rights for the identity '{0}' are in desired state. (FSAR0013)
    EvaluatingIndividualRight = The identity '{0}' currently have the rights '{1}', and should not have '{2}'. Evaluating each individual right against the current state. (FSAR0014)
    IndividualRightNotInDesiredState = The right '{1}' is not in desired state. The identity '{0}' should not have the right '{1}', but as part of the rights in the current state the identity is given that right. (FSAR0015)
    IndividualRightInDesiredState = The right '{0}' is in desired state. The right is not included with any of the rights in the current state. (FSAR0016)
    NoRightsWereSpecified = No rights were specified for the identity '{0}' for the path '{1}'. (FSAR0017)
    EvaluatingRights = Evaluating the rights for the identity '{0}'. (FSAR0018)
    NotInDesiredState = The identity '{0}' has the rights '{1}', but expected the rights to also include '{2}' (combined from desired rights '{3}'). (FSAR0019)
    FailedToSetAccessRules = Failed to set the changed access rules for the path '{0}'. (FSAR0020)
    SetAllowAccessRule = Setting the allow access rules '{0}' for the identity '{1}' on the path '{2}'. (FSAR0021)
    RemoveAllAllowAccessRules = Removing all allow access rules for the identity '{0}' on the path '{1}'. (FSAR0022)
    RemoveAllowAccessRule = Removing the allow access rule '{0}' for the identity '{1}' on the path '{2}'. (FSAR0023)
'@
