source("experiments/feeding-access-policy.R")

validate_feeding_access_policy <- function() {
  memory <- new_feeding_memory(3L)
  stopifnot(
    is.list(memory),
    identical(
      names(memory),
      c(
        "last_return_kj_h",
        "best_return_kj_h",
        "last_observed_day",
        "inadequacy_kj"
      )
    ),
    identical(memory$last_return_kj_h, rep(200, 3L)),
    identical(memory$best_return_kj_h, rep(250, 3L)),
    identical(memory$last_observed_day, rep(0, 3L)),
    identical(memory$inadequacy_kj, 0)
  )

  # A large deficit cannot make a lower-return destination acceptable.
  stopifnot(
    identical(
      choose_feeding_station(
        1L,
        c(150, 149),
        c(0, 0),
        c(0, 0),
        inadequacy_kj = 1e12
      ),
      1L
    )
  )

  # Adequacy retains the current station even when another station scores well.
  stopifnot(
    identical(
      choose_feeding_station(
        1L,
        c(200, 400),
        c(0, 0),
        c(0, 0),
        inadequacy_kj = 1e12
      ),
      1L
    )
  )

  stopifnot(
    identical(
      choose_feeding_station(
        1L,
        c(150, 250),
        c(0, 4),
        c(0, 100)
      ),
      2L
    ),
    identical(
      choose_feeding_station(
        1L,
        c(150, 151),
        c(0, 31),
        c(0, 100)
      ),
      1L
    )
  )

  # Return recovery depends on elapsed unobserved days, using the opening clock.
  observed <- update_feeding_memory(
    memory,
    intake_kg_dm = c(.02, 0, 0),
    feeding_h = c(1, 0, 0),
    day = 1L,
    current_index = 1L
  )
  unchanged <- update_feeding_memory(
    observed,
    intake_kg_dm = rep(0, 3L),
    feeding_h = rep(0, 3L),
    day = 2L,
    current_index = 1L
  )
  stopifnot(
    identical(unchanged, observed),
    identical(feeding_expected_return(unchanged, 2L), c(200, 225, 225)),
    identical(feeding_expected_return(unchanged, 3L), c(225, 250, 250))
  )

  # Zero feeding opportunity is excluded from the observed return update.
  zero_opportunity <- update_feeding_memory(
    memory,
    intake_kg_dm = c(.05, .02, 0),
    feeding_h = c(0, 1, 0),
    day = 2L,
    current_index = 2L
  )
  stopifnot(
    zero_opportunity$last_return_kj_h[[1L]] == 200,
    zero_opportunity$last_return_kj_h[[2L]] == 200,
    zero_opportunity$last_observed_day[[1L]] == 0,
    zero_opportunity$last_observed_day[[2L]] == 2
  )

  # Policy functions return new values without mutating their input record.
  before <- observed
  invisible(feeding_expected_return(observed, 5L))
  invisible(choose_feeding_station(1L, c(150, 250), c(0, 4), c(0, 100)))
  invisible(update_feeding_memory(
    observed,
    intake_kg_dm = c(.01, 0, 0),
    feeding_h = c(1, 0, 0),
    day = 4L,
    current_index = 1L
  ))
  stopifnot(identical(observed, before))

  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  validate_feeding_access_policy()
  cat("Feeding access policy validation passed.\n")
}
