#' Vine copula models
#' 
#' Automated fitting or creation of custom vine copula models
#' 
#' @aliases vinecop_dist
#' @inheritParams bicop
#' @param family_set a character vector of families; see [bicop()] for 
#' additional options.
#' @param structure an `rvine_structure` object, namely a compressed 
#' representation of the vine structure, or an object that can be coerced 
#' into one (see [rvine_structure()] and [as_rvine_structure()]).
#' The dimension must be `length(pair_copulas[[1]]) + 1`; for [vinecop()], 
#' `structure = NA` performs automatic structure selection.
#' @param psi0 prior probability of a non-independence copula (only used for
#'     `selcrit = "mbic"` and `selcrit = "mbicv"`).
#' @param trunc_lvl the truncation level of the vine copula; `Inf` means no
#'   truncation, `NA` indicates that the truncation level should be selected
#'   automatically by [mBICV()].
#' @param tree_crit the criterion for tree selection, one of `"tau"`, `"rho"`,
#'    `"hoeffd"`, or `"mcor"` for Kendall's \eqn{\tau}, Spearman's \eqn{\rho}, 
#'    Hoeffding's \eqn{D}, and maximum correlation, respectively.
#' @param threshold for thresholded vine copulas; `NA` indicates that the 
#'   threshold should be selected automatically by [mBICV()].
#' @param show_trace logical; whether a trace of the fitting progress should be 
#'    printed.
#' @param cores number of cores to use; if more than 1, estimation of pair 
#'    copulas within a tree is done in parallel.
#' 
#' @details
#' [vinecop_dist()] creates a vine copula by specifying a nested list of 
#' [bicop_dist()] objects and a quadratic structure matrix. 
#' 
#' [vinecop()] provides automated fitting for vine copula models. 
#' The function inherits the parameters of [bicop()]. 
#' Optionally, an [rvine_structure()] or [rvine_matrix()] can be used as
#' input to specify the vine structure. `tree_crit` describes the
#' criterion for tree selection, one of `"tau"`, `"rho"`, `"hoeffd"` for
#' Kendall's tau, Spearman's rho, and Hoeffding's D, respectively. Additionally, 
#' `threshold` allows to threshold the `tree_crit` and `trunc_lvl` to truncate 
#' the vine copula, with `threshold_sel` and `trunc_lvl_sel` to automatically 
#' select both parameters.
#'
#' @return Objects inheriting from `vinecop_dist` for [vinecop_dist()], and
#' `vinecop` and `vinecop_dist` for [vinecop()].
#' 
#' Object from the `vinecop_dist` class are lists containing:
#' 
#' * `pair_copulas`, a list of lists. Each element of `pair_copulas` corresponds 
#' to a tree, which is itself a list of `bicop_dist` objects, see [bicop_dist()].
#' * `structure`, an `rvine_structure` object, namely a compressed 
#' representation of the vine structure, or an object that can be coerced 
#' into one (see [rvine_structure()] and [as_rvine_structure()]).
#' * `npars`, a `numeric` with the number of (effective) parameters.
#' 
#' For objects from the `vinecop` class, elements of the sublists in 
#' `pair_copulas` are also `bicop` objects, see [bicop()]. Additionally, 
#' objects from the `vinecop` class contain:
#' 
#' * `threshold`, the (set or estimated) threshold used for thresholding the vine.
#' * `data` (optionally, if `keep_data = TRUE` was used), the dataset that was 
#' passed to [vinecop()].
#' * `controls`, a `list` with the set of fit controls that was passed to [vinecop()].
#' * `nobs`, an `integer` with the number of observations that was used 
#' to fit the model.
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
#' # set up vine copula model
#' vc <- vinecop_dist(pcs, mat)
#' 
#' # show model
#' summary(vc)
#' 
#' # simulate some data
#' u <- rvinecop(50, vc)
#' 
#' # estimate a vine copula model
#' fit <- vinecop(u, "par")
#' fit
#' summary(fit)
#' str(fit, 3)
#' 
#' @export
vinecop <- function(data, family_set = "all", structure = NA, 
                    par_method = "mle", nonpar_method = "constant", mult = 1, 
                    selcrit = "bic", weights = numeric(), psi0 = 0.9, 
                    presel = TRUE, trunc_lvl = Inf, tree_crit = "tau", 
                    threshold = 0, keep_data = FALSE, show_trace = FALSE, 
                    cores = 1) {
    assert_that(
        is.character(family_set),
        inherits(structure, "matrix") || 
            inherits(structure, "rvine_structure") || 
            (is.scalar(structure) && is.na(structure)),
        is.string(par_method), 
        is.string(nonpar_method),
        is.number(mult), mult > 0,
        is.string(selcrit),
        is.numeric(weights),
        is.number(psi0), psi0 > 0, psi0 < 1,
        is.flag(presel),
        is.scalar(trunc_lvl),
        is.string(tree_crit),
        is.scalar(threshold),
        is.flag(keep_data),
        is.number(cores), cores > 0
    )
    
    # check if families known (w/ partial matching) and expand convenience defs
    family_set <- process_family_set(family_set)
    
    ## pre-process input
    data <- if_vec_to_matrix(data)
    is_structure_provided <- !(is.scalar(structure) && is.na(structure))
    if (is_structure_provided)
        structure <- as_rvine_structure(structure)
    
    ## fit and select copula model
    vinecop <- vinecop_select_cpp(
        data = data, 
        is_structure_provided = is_structure_provided,
        structure = structure,
        family_set = family_set,
        par_method = par_method,
        nonpar_method = nonpar_method,
        mult = mult,
        selection_criterion = selcrit,
        weights = weights,
        psi0 = psi0,
        preselect_families = presel,
        truncation_level = ifelse(  # Inf cannot be passed to C++
            is.finite(trunc_lvl),
            trunc_lvl, 
            .Machine$integer.max
        ),
        tree_criterion = tree_crit,
        threshold = threshold,
        select_truncation_level = is.na(trunc_lvl),
        select_threshold = is.na(threshold),
        show_trace = show_trace,
        num_threads = cores
    )
    
    ## make all pair-copulas bicop objects
    vinecop$pair_copulas <- lapply(
        vinecop$pair_copulas, 
        function(tree) lapply(tree, as.bicop)
    )
    
    ## make the structure a rvine-structure object
    class(vinecop$structure) <- c("rvine_structure", class(vinecop$structure))
    
    ## add information about the fit
    vinecop$names <- colnames(data)
    if (keep_data) {
        vinecop$data <- data
    }
    vinecop$controls <- list(
        family_set = family_set,
        par_method = par_method,
        nonpar_method = nonpar_method,
        mult = mult,
        selcrit = selcrit,
        weights = weights,
        presel = presel,
        trunc_lvl = trunc_lvl,
        tree_crit = tree_crit,
        threshold = threshold
    )
    vinecop$nobs <- nrow(data)
    
    structure(vinecop, class = c("vinecop", "vinecop_dist"))
}

#' @param pair_copulas A nested list of 'bicop_dist' objects, where 
#'    \code{pair_copulas[[t]][[e]]} corresponds to the pair-copula at edge `e` in
#'    tree `t`.
#' @rdname vinecop
#' @export
vinecop_dist <- function(pair_copulas, structure) {
    
    # create object
    vinecop <- structure(
        list(pair_copulas = pair_copulas, 
             structure = as_rvine_structure(structure)),
        class = "vinecop_dist"
    )
    
    # sanity checks
    assert_that(is.list(pair_copulas))
    if (length(pair_copulas) > length(pair_copulas[[1]])) {
        stop("'pair_copulas' has more trees than variables.")
    }

    pc_lst <- unlist(pair_copulas, recursive = FALSE)
    if (!all(sapply(pc_lst, function(x) inherits(x, "bicop_dist")))) {
        stop("some objects in pair_copulas aren't of class 'bicop_dist'")
    }

    vinecop$structure <- truncate_model(vinecop$structure, 
                                        length(vinecop$pair_copulas))
    vinecop_check_cpp(vinecop)
    vinecop$npars <- sum(sapply(pc_lst, function(x) x[["npars"]]))
    vinecop$loglik <- NA
    
    vinecop
}
