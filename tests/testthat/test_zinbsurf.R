context("Test zinbsurf function.")
set.seed(13124)

BiocParallel::register(BiocParallel::SerialParam())

se <- SummarizedExperiment(matrix(rpois(300, lambda=5), nrow=10, ncol=30),
                           colData = data.frame(bio = gl(2, 15)))
colnames(se) <- paste0("cell", 1:30)

test_that("zinbsurf works with range of proportions", {
    set.seed(987)

    props <- c(.3, .5, .7)
    expect_silent(lapply(props, function(p) {
        m1 <- zinbsurf(se, K=2, which_assay=1, prop_fit = p)
    }))

    expect_error(zinbsurf(se, K=2, which_assay=1, prop_fit=1),
                 "`prop_fit` must be in.")
})

test_that("one-dimensional W", {
    expect_silent(fit <- zinbsurf(se, K = 1, which_assay = 1))

    expect_equal(NCOL(reducedDim(fit)), 1)
})

test_that("zinbsurf works with slot counts", {
    set.seed(987)

    cc <- matrix(rpois(300, lambda=5), nrow=10, ncol=30)
    ll <- matrix(rnorm(300), nrow=10, ncol=30)

    se <- SummarizedExperiment(assays = list(counts = cc, norm = ll),
                               colData = data.frame(bio = gl(2, 15)))
    colnames(se) <- paste0("cell", 1:30)

    set.seed(123)
    expect_silent(m1 <- zinbsurf(se, K = 2, prop_fit = .5))
    set.seed(123)
    expect_silent(m2 <- zinbsurf(se, K = 2,  prop_fit = .5,
                                 which_assay = "counts"))
    expect_equal(m1, m2)

    se <- SummarizedExperiment(assays = list(counts = cc, norm = ll),
                               colData = data.frame(bio = gl(2, 15)))
    colnames(se) <- paste0("cell", 1:30)

    set.seed(123)
    expect_silent(m1 <- zinbsurf(se, K = 2, prop_fit = .5))
    set.seed(123)
    expect_silent(m2 <- zinbsurf(se, K = 2,  prop_fit = .5,
                                 which_assay = "counts"))
    expect_equal(m1, m2)
})


test_that("zinbsurf works without slot counts", {
    set.seed(987)

    cc <- matrix(rpois(300, lambda=5), nrow=10, ncol=30)
    ll <- matrix(rnorm(300), nrow=10, ncol=30)

    se <- SummarizedExperiment(assays = list(assay1 = cc, assay2 = ll),
                               colData = data.frame(bio = gl(2, 15)))
    colnames(se) <- paste0("cell", 1:30)

    set.seed(123)
    expect_warning(m1 <- zinbsurf(se, K = 2, prop_fit = .5))
    set.seed(123)
    expect_silent(m2 <- zinbsurf(se, K = 2, prop_fit = .5, which_assay = "assay1"))
    expect_equal(m1, m2)
})

test_that("zinbsurf works with subset of genes", {
    set.seed(987)

    cc <- matrix(rpois(300, lambda=5), nrow=10, ncol=30)
    rownames(cc) <- paste0("gene", 1:10)
    colnames(cc) <- paste0("cell", 1:30)

    wh_genes <- c(rep(TRUE, 2), rep(FALSE, 8))
    se <- SummarizedExperiment(assays = list(counts = cc),
                               colData = data.frame(bio = gl(2, 15)),
                               rowData = data.frame(wh_genes = wh_genes))

    ## check that it works with all genes
    set.seed(123)
    expect_silent(m1 <- zinbsurf(se, K=1, prop_fit = .5))
    set.seed(123)
    expect_silent(m2 <- zinbsurf(se, K=1, prop_fit = .5, which_genes = rownames(cc)))
    set.seed(123)
    expect_silent(m3 <- zinbsurf(se, K=1, prop_fit = .5, which_genes = 1:10))
    set.seed(123)
    expect_silent(m4 <- zinbsurf(se, K=1, prop_fit = .5, which_genes = rep(TRUE, 10)))

    expect_equal(m1, m2)
    expect_equal(m1, m3)
    expect_equal(m1, m4)

    ## check that it works with both a vector and a rowData column
    set.seed(155)
    expect_silent(m1 <- zinbsurf(se, K=1, prop_fit = .5, which_genes = wh_genes))
    set.seed(155)
    expect_silent(m2 <- zinbsurf(se, K=1, prop_fit = .5, which_genes = "wh_genes"))

    expect_equal(m1, m2)
})

test_that("zinbsurf fails when it needs to", {
    set.seed(987)

    cc <- matrix(rpois(300, lambda=5), nrow=10, ncol=30)
    wh_genes <- c(rep(TRUE, 2), rep(FALSE, 8))

    se <- SummarizedExperiment(assays = list(counts = cc),
                               colData = data.frame(bio = gl(2, 15)),
                               rowData = data.frame(wh_genes = wh_genes))
    assay(se, "logcounts") <- log(assay(se))

    set.seed(123)
    expect_error(zinbsurf(se, K=1, prop_fit = .5), "colnames")

    rownames(se) <- paste0("gene", 1:10)
    colnames(se) <- paste0("cell", 1:30)
    expect_error(zinbsurf(se, K=0, prop_fit = .5), "K > 0")
    expect_error(zinbsurf(se, prop_fit = .5), "missing")
    expect_error(zinbsurf(se, prop_fit = .5,
                          K=1, which_genes=1), "which_genes")
    expect_error(zinbsurf(se, prop_fit = .5,
                          K=1, X="~bio2"), "variables in colData")
    expect_error(zinbsurf(se, prop_fit = .5,
                          K=1, V="~bio2"), "variables in rowData")
    expect_error(zinbsurf(se, prop_fit = .5,
                          K=1, which_assay = "logcounts"))

})

test_that("zinbsurf works with covariates", {
    set.seed(987)

    cc <- matrix(rpois(300, lambda=5), nrow=10, ncol=30)
    rownames(cc) <- paste0("gene", 1:10)
    colnames(cc) <- paste0("cell", 1:30)

    cov <- rnorm(10)

    se <- SummarizedExperiment(assays = list(counts = cc),
                               colData = data.frame(bio = gl(2, 15)),
                               rowData = data.frame(cov = cov))

    expect_no_error(m1 <- zinbsurf(se, K=1, prop_fit = .5,
                                 X = "~bio"))

    expect_no_error(m1 <- zinbsurf(se, K=1, prop_fit = .5,
                                 V = "~cov"))

    expect_no_error(m1 <- zinbsurf(se, K=1, prop_fit = .5,
                                 V = "~cov", X = "~bio"))

    expect_no_error(m1 <- zinbsurf(se, K=1, prop_fit = .5,
                                 zeroinflation = FALSE))
})
