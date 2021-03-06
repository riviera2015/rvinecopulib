context("Class 'rvine_structure'")

mat <- matrix(c(1, 2, 3, 4, 1, 2, 3, 0, 1, 2, 0, 0, 1, 0, 0, 0), 4, 4)
mylist <- list(order = 1:4, struct_array = list(c(1, 1, 1), c(2, 2), 3))

test_that("constructor and as/is generics work", {
    expect_silent(rvs <- as_rvine_structure(mylist)) ## calls the constructor
    expect_silent(rvm <- as_rvine_matrix(mylist)) ## true coercion
    expect_silent(as_rvine_structure(mat)) ## calls the constructors
    expect_silent(as_rvine_matrix(mat)) ## true coercion
    expect_true(is.rvine_structure(rvs))
    expect_true(is.rvine_matrix(rvm))
})

test_that("print/dim generics work", {
    rvs <- as_rvine_structure(mylist)
    rvm <- as_rvine_matrix(mat)
    expect_output(print(rvs))
    expect_output(print(rvm))
    expect_equivalent(dim(rvs), c(4, 3))
    expect_equivalent(dim(rvm), c(4, 3))
})
