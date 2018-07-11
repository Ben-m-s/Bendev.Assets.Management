enum CopyMode{
    Default = 0 # The asset will be copied only if it has no sub-assets
    Copy = 1 # The asset will be copied regardless of not having sub-assets
    Skip = 2 # The asset will not be copied regardless of having sub-assets
}