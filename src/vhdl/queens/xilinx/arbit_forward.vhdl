-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-------------------------------------------------------------------------------
-- This file is part of the Queens@TUD solver suite
-- for enumerating and counting the solutions of an N-Queens Puzzle.
--
-- Copyright (C) 2008-2015
--      Thomas B. Preusser <thomas.preusser@utexas.edu>
-------------------------------------------------------------------------------
-- This design is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Modifications to this work must be clearly identified and must leave
-- the original copyright statement and contact information intact. This
-- license notice may not be removed.
--
-- This design is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this design.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity arbit_forward is
  generic (
    N : positive                            -- Length of Token Chain
  );
  port (
    tin  : in  std_logic;                   -- Fed Token
    have : in  std_logic_vector(0 to N-1);  -- Token Owner
    pass : in  std_logic_vector(0 to N-1);  -- Token Passers
    grnt : out std_logic_vector(0 to N-1);  -- Token Output
    tout : out std_logic                    -- Unused Token
  );
end arbit_forward;

library UNISIM;
use UNISIM.vcomponents.all;

architecture rtl_xilinx of arbit_forward is

  -- Intermediate Token Signals
  signal q : std_logic_vector(0 to N);

begin

  -- First MUXCY only with switching LUT
  q(0) <= have(0) or (tin and pass(0));
  MUXCY_inst : MUXCY
    port map (
      O  => q(1),               -- Carry output signal
      CI => '1',                -- Carry input signal
      DI => '0',                -- Data input signal
      S  => q(0)                -- MUX select
    );
  grnt(0) <= tin and not pass(0);

  genChain: for i in 1 to N-1 generate
    signal p : std_logic;
  begin
    --q(i+1) <= have(i) or (q(i) and pass(i));
    p <= pass(i) and not have(i);
    MUXCY_inst : MUXCY
      port map (
        O  => q(i+1),                 -- Carry output signal
        CI => q(i),                   -- Carry input signal
        DI => have(i),                -- Data input signal
        S  => p                      -- MUX select
      );

    grnt(i) <= q(i) and not q(i+1);
  end generate;
  tout <= q(N);

end rtl_xilinx;
