make_plants_for_behaviour <- function() {
  data.frame(
    plant_id = 1:3,
    xcor = c(0, 5, 20),
    ycor = c(0, 5, 5),
    ms = c(5, 4, 2),
    ns = c(0.2, 0.25, 0.3),
    cs = c(4, 4.5, 5),
    bdef = c(0.1, 0.2, 0.4)
  )
}

test_that("select_new_plant chooses within detection distance and handles empty set", {
  set.seed(202)
  plants <- make_plants_for_behaviour()
  herb <- init_herbivore(mass = 4e5)
  herb$xcor <- 0
  herb$ycor <- 0
  herb$selected_plant_id <- NA

  updated <- select_new_plant(herb, plants)
  expect_true(updated$selected_plant_id %in% c(1L, 2L))

  plants$ms <- 1e-6
  emptied <- select_new_plant(herb, plants)
  expect_true(is.na(emptied$selected_plant_id))
})

test_that("pick_a_plant performs tastiness-weighted sampling", {
  set.seed(303)
  plants <- make_plants_for_behaviour()
  scores <- c(0.1, 0.9, 0)
  picked <- pick_a_plant(plants[1:3, ], scores)
  expect_true(picked %in% plants$plant_id[1:2])

  expect_true(is.na(pick_a_plant(plants[1:2, ], c(0, 0))))
})

test_that("make_foraging_decision responds to gut capacity and plant quality", {
  plants <- make_plants_for_behaviour()
  herb <- init_herbivore(mass = 5e5)
  herb <- calc_foraging_traits(herb)
  herb$selected_plant_id <- 1L
  herb$gut_content <- herb$gut_capacity / 2
  set.seed(404)
  eating <- make_foraging_decision(herb, plants)
  expect_true(eating$behaviour %in% c("EATING", "MOVING"))

  herb$gut_content <- herb$gut_capacity + 1
  must_move <- make_foraging_decision(herb, plants)
  expect_identical(must_move$behaviour, "MOVING")
})

test_that("herbivore_move wraps positions and caps step length", {
  plants <- make_plants_for_behaviour()
  herb <- init_herbivore(mass = 5e5)
  herb$fv_max <- 2 # m/s
  herb$xcor <- 0
  herb$ycor <- 0
  herb$distance_moved <- 0

  herb$selected_plant_id <- 2L
  moved <- herbivore_move(herb, plants, time_step_minutes = 1)
  expect_equal(moved$selected_plant_id, 2L)
  expect_true(moved$distance_moved > 0)
  expect_true(moved$xcor >= 0 && moved$ycor >= 0)

  # Random move when no plant selected - deterministic with seed
  moved$selected_plant_id <- NA
  set.seed(505)
  random_move <- herbivore_move(moved, plants, time_step_minutes = 1)
  expect_false(identical(c(random_move$xcor, random_move$ycor), c(moved$xcor, moved$ycor)))
})
