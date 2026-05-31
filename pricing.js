// Brake Knights pricing table.
// partsLabor: parts + labor combined, in USD.
// shopSupplies: flat shop supply fee, in USD.
// taxRate: applied to (partsLabor + shopSupplies). Set to 0 if tax is included in price.

module.exports = {
  taxRate: 0.00,
  services: {
    'Front Pads':                              { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Rear Pads':                               { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Front and Rear Pads':                     { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Front Pads and Rotors':                   { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Rear Pads and Rotors':                    { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Front and Rear Pads and Rotors':          { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Front Rotors':                            { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Rear Rotors':                             { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Front and Rear Rotors':                   { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Drums and Shoes':                         { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Front Pads, Rotors, and Drums and Shoes': { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Brake Fluid Flush':                       { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Brake Inspection':                        { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Caliper Replacement':                     { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Brake Hose Replacement':                  { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
    'Describe Issue / Not Sure':               { standard: { partsLabor: 0, shopSupplies: 0 }, premium: { partsLabor: 0, shopSupplies: 0 } },
  }
};
