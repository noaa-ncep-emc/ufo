/*
 * (C) Copyright 2017 UCAR
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#ifndef UFO_ATMOSPHERE_RADIOSONDE_OBSRADIOSONDE_INTERFACE_H_
#define UFO_ATMOSPHERE_RADIOSONDE_OBSRADIOSONDE_INTERFACE_H_

#include "ioda/ObsSpace.h"

#include "ufo/Fortran.h"

// Forward declarations
namespace util {
  class DateTime;
}

namespace ufo {

/// Interface to Fortran UFO routines
/*!
 * The core of the UFO is coded in Fortran.
 * Here we define the interfaces to the Fortran code.
 */

extern "C" {

// -----------------------------------------------------------------------------
//  Radiosonde observation operator
// -----------------------------------------------------------------------------

  void ufo_radiosonde_setup_f90(F90hop &, const eckit::Configuration * const *,
                                char *, char *, const int &);
  void ufo_radiosonde_delete_f90(F90hop &);
  void ufo_radiosonde_simobs_f90(const F90hop &, const F90goms &, const ioda::ObsSpace &,
                                 const int &, double &, const F90obias &);
  void ufo_radiosonde_locateobs_f90(const F90hop &, const ioda::ObsSpace &,
                                    const util::DateTime * const *,
                                    const util::DateTime * const *, F90locs &);
// -----------------------------------------------------------------------------

}  // extern C

}  // namespace ufo
#endif  // UFO_ATMOSPHERE_RADIOSONDE_OBSRADIOSONDE_INTERFACE_H_
