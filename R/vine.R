#' Vine copula models
#' 
#' Automated fitting or creation of custom vine copula models
#' 
#' @aliases vine_dist
#' @param data a matrix or data.frame.
#' @param margins_controls a list with arguments to be passed to 
#' [kde1d::kde1d()]. Currently, there can be 
#'   * `mult` numeric; all bandwidths for marginal kernel density estimation
#'   are multiplied with \code{mult_1d}. Defaults to `log(1 + d)` where `d` is
#'   the number of variables after applying [cctools::expand_as_numeric()].
#'   * `xmin` numeric vector of length d; see [kde1d::kde1d()].
#'   * `xmax` numeric vector of length d; see [kde1d::kde1d()].
#'   * `bw` numeric vector of length d; see [kde1d::kde1d()].
#' @param copula_controls a list with arguments to be passed to [vinecop()].
#' 
#' @details
#' `vine_dist()` creates a vine copula by specifying the margins, a nested list 
#' of `bicop_dist` objects and a quadratic structure matrix. 
#' 
#' `vine()` provides automated fitting for vine copula models. 
#' `margins_controls` is a list with the same parameters as 
#' [kde1d::kde1d()] (except for `x`). `copula_controls` is a list 
#' with the same parameters as [vinecop()] (except for `data`). 
#'
#' @return Objects inheriting from `vine_dist` for [vine_dist()], and
#' `vine` and `vine_dist` for [vine()].
#' 
#' Objects from the `vine_dist` class are lists containing:
#' 
#' * `margins`, a list of marginals (see below).
#' * `copula`, an object of the class `vinecop_dist`, see [vinecop_dist()].
#' 
#' For objects from the `vine` class, `copula` is also an object of the class
#' `vine`, see [vinecop()]. Additionally, objects from the `vine` class contain:
#' 
#' * `margins_controls`, a `list` with the set of fit controls that was passed 
#' to [kde1d::kde1d()] when estimating the margins.
#' * `copula_controls`, a `list` with the set of fit controls that was passed 
#' to [vinecop()] when estimating the copula.
#' * `data` (optionally, if `keep_data = TRUE` was used), the dataset that was 
#' passed to [vinecop()].
#' * `nobs`, an `integer` containing the number of observations that was used 
#' to fit the model.
#' 
#' Concerning `margins`:
#' 
#' * For objects created with [vine_dist()], it simply corresponds to the `margins` 
#' argument.
#' * For objects created with [vine()], it is a list of objects of class `kde1d`, 
#' see [kde1d::kde1d()].
#' 
#' @examples
#' # specify pair-copulas
#' bicop <- bicop_dist("bb1", 90, c(3, 2))
#' pcs <- list(
#'     list(bicop, bicop),  # pair-copulas in first tree 
#'     list(bicop)          # pair-copulas in second tree 
#'  )
#'  
#' # specify R-vine matrix
#' mat <- matrix(c(1, 2, 3, 1, 2, 0, 1, 0, 0), 3, 3) 
#' 
#' # set up vine copula model with Gaussian margins
#' vc <- vine_dist(list(distr = "norm"), pcs, mat)
#' 
#' # show model
#' summary(vc)
#' 
#' # simulate some data
#' x <- rvine(50, vc)
#' 
#' # estimate a vine copula model
#' fit <- vine(x, copula_controls = list(family_set = "par"))
#' summary(fit)
#' 
#' @importFrom kde1d kde1d dkde1d pkde1d qkde1d
#' @importFrom cctools cont_conv expand_vec
#' @export
vine <- function(data, 
                 margins_controls = list(mult = NULL, 
                                      xmin = NaN, 
                                      xmax = NaN, 
                                      bw = NA), 
                 copula_controls = list(family_set = "all", 
                                     structure = NA, 
                                     par_method = "mle", 
                                     nonpar_method = "constant",
                                     mult = 1, 
                                     selcrit = "bic", 
                                     psi0 = 0.9, 
                                     presel = TRUE, 
                                     trunc_lvl = Inf, 
                                     tree_crit = "tau", 
                                     threshold = 0, 
                                     keep_data = FALSE,
                                     show_trace = FALSE, 
                                     cores = 1)) {
    
    ## continuous convolution
    data_cc <- cont_conv(data)
    
    ## basic sanity checks (copula_controls are checked by vinecop)
    assert_that(NCOL(data_cc) > 1, msg = "data must be multivariate.")
    d <- ncol(data_cc)
    assert_that(is.list(margins_controls))
    assert_that(in_set(names(margins_controls), c("mult", "xmin", "xmax", "bw")))
    assert_that(is.list(copula_controls))
    if (is.null(copula_controls$keep_data))
        copula_controls$keep_data <- TRUE
    
    ## expand the required arguments and compute default mult if needed
    margins_controls <- expand_margin_controls(margins_controls, d, data)

    ## estimation of the marginals
    vine <- list()
    vine$margins <- lapply(1:d, function(k) kde1d(data_cc[, k],
                                                  xmin = margins_controls$xmin[k], 
                                                  xmax = margins_controls$xmax[k],
                                                  bw = margins_controls$bw[k],
                                                  mult = margins_controls$mult))
    vine$margins_controls <- margins_controls

    ## estimation of the R-vine copula (only if d > 1)
    if (d > 1) {
        ## transform to copula data
        copula_controls$data <- sapply(1:d, function(k) pkde1d(data_cc[, k],
                                                            vine$margins[[k]]))
        
        ## to avoid saving copula data
        keep_data <- copula_controls$keep_data
        copula_controls$keep_data <- FALSE
        
        ## estimate the copula
        vine$copula  <- do.call(vinecop, copula_controls)
        
        ## to potentially save the data on the standard scale
        copula_controls$keep_data <- keep_data
    }
    vine$copula_controls <- copula_controls[-which(names(copula_controls) == "data")]
    
    finalize_vine(vine, data_cc, keep_data)
}

#' @param margins A list with with each element containing the specification of a 
#' marginal [stats::Distributions]. Each marginal specification 
#' should be a list with containing at least the distribution family (`"distr"`) 
#' and optionally the parameters, e.g. 
#' `list(list(distr = "norm"), list(distr = "norm", mu = 1), list(distr = "beta", shape1 = 1, shape2 = 1))`.
#' Note that parameters that have no default values have to be provided. 
#' Furthermore, if `margins` has length one, it will be recycled for every component.
#' @param pair_copulas A nested list of 'bicop_dist' objects, where 
#'    \code{pair_copulas[[t]][[e]]} corresponds to the pair-copula at edge `e` in
#'    tree `t`.
#' @param structure an `rvine_structure` object, namely a compressed 
#' representation of the vine structure, or an object that can be coerced 
#' into one (see [rvine_structure()] and [as_rvine_structure()]).
#' The dimension must be `length(pair_copulas[[1]]) + 1`.
#' @rdname vine
#' @export
vine_dist <- function(margins, pair_copulas, structure) {
    
    structure <- as_rvine_structure(structure)
    
    # sanity checks for the marg
    if (!(length(margins) %in% c(1, dim(structure)[1])))
        stop("marg should have length 1 or dim(structure)[1]")
    stopifnot(is.list(margins))
    if (depth(margins) == 1) {
        check_marg <- check_distr(margins)
        npars_marg <- ncol(matrix) * get_npars_distr(margins)
    } else {
        check_marg <- lapply(margins, check_distr)
        npars_marg <- sum(sapply(margins, get_npars_distr))
    }
    is_ok <- sapply(check_marg, isTRUE)
    if (!all(is_ok)) {
        msg <- "Some objects in marg aren't properly defined.\n"
        msg <- c(msg, paste0("margin ", seq_along(check_marg)[!is_ok], " : ",
                             unlist(check_marg[!is_ok]), ".", sep = "\n"))
        stop(msg)
    }

    # create the vinecop object
    copula <- vinecop_dist(pair_copulas, structure)
    
    # create object
    structure(list(margins = margins, 
                   copula = copula,
                   npars = copula$npars + npars_marg,
                   loglik = NA), class = "vine_dist")
}

expand_margin_controls <- function(controls, d, data) {
    default_controls <- list(mult = NULL, xmin = NaN, xmax = NaN, bw = NA)
    controls <- modifyList(default_controls, controls)
    if (is.null(controls[["mult"]])) 
        controls[["mult"]] <- log(1 + d)
    for (par in setdiff(names(controls), "mult"))
        controls[[par]] <- expand_vec(controls[[par]], data)
    controls
}

finalize_vine <- function(vine, data, keep_data) {
    ## compute npars/loglik and adjust margins for discrete data and 
    npars <- loglik <- 0
    for (k in seq_len(ncol(data))) {
        npars <- npars + vine$margins[[k]]$edf
        loglik <- loglik + vine$margins[[k]]$loglik
        if (k %in% attr(data, "i_disc")) {
            vine$margins[[k]]$jitter_info$i_disc[1] <- 1
            vine$margins[[k]]$jitter_info$levels$x <- attr(data, "levels")[[k]]
        }
    }
    
    ## add the npars/loglik of the copulas
    vine$npars <- npars + vine$copula$npars
    vine$loglik <- loglik + vine$copula$loglik
    
    ## add data
    if (keep_data) {
        vine$data <- data
    } else {
        vine$data <- matrix(NA, ncol = ncol(data))
        colnames(vine$data) <- colnames(data)
        attr(vine$data, "i_disc") <- attr(data, "i_disc")
        attr(vine$data, "levels") <- attr(data, "levels")
    }
    
    ## add number of observations
    vine$nobs <- nrow(data)
    vine$names <- vine$copula$names <- colnames(data)

    ## create and return object
    structure(vine, class = c("vine", "vine_dist"))
}