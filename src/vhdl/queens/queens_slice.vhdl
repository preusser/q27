-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-------------------------------------------------------------------------------
-- This file is part of the Queens@TUD solver suite
-- for enumerating and counting the solutions of an N-Queens Puzzle.
--
-- Copyright (C) 2008-2015
--      Thomas B. Preusser <thomas.preusser@utexas.edu>
--      Benedikt Reuter    <breutr@gmail.com>
-------------------------------------------------------------------------------
-- This design is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this design.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity queens_slice is
  generic (
    N : positive;                       -- size of field
    L : positive                        -- number of preplaced outer rings
  );
  port (
    -- Global Clock
    clk : in std_logic;
    rst : in std_logic;

    -- Inputs (strobed)
    start : in std_logic;  -- Strobe for Start
    BH_l  : in std_logic_vector(0 to N-2*L-1);  -- Blocking for leftmost Column
    BU_l  : in std_logic_vector(0 to 2*N-4*L-2);
    BD_l  : in std_logic_vector(0 to 2*N-4*L-2);  -- 0 to 6
    BV_l  : in std_logic_vector(0 to N-2*L-1);

    -- Output Strobes
    sol  : out std_logic;
    done : out std_logic
  );
end queens_slice;


library IEEE;
use IEEE.numeric_std.all;

architecture rtl of queens_slice is

  ---------------------------------------------------------------------------
  -- Matrix to iterate through
  --   These types are plain ugly but the multidiemsional tMatrix(<>, <>)
  --   is not slicable. Thus, these types are still better than lots of
  --   generate loops working through the columns.
  subtype tColumn is std_logic_vector(L to N-L-1);
  type tField is array(L to N-L-1) of tColumn;

  -- Placed Queen Matrix
  signal QN : tField := (others => (others => '-'));

  component arbit_forward
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
  end component;

  -- Blocking Signals
  signal BH : std_logic_vector(  L   to N-L-1)     := (others => '-');  -- Window: L to N-L-1
  signal BV : std_logic_vector(2*L+1 to 2*N-2*L-1) := (others => '-');  -- Window: N
                                                                        -- put shifts left
  signal BU : std_logic_vector(2*L+1 to 3*N-4*L-2) := (others => '-');  -- Window: N to 2*N-2*L-1
                                                                        -- put shifts right
  signal BD : std_logic_vector(2*L+1 to 3*N-4*L-2) := (others => '-');  -- Window: N to 2*N-2*L-1
                                                                        -- put shifts left
  signal s    : std_logic_vector(L to N-L-1);
  signal put  : std_logic;

begin

  assert false
    report LF&
    "Queens@TUD Solver Slice " &LF&
    "Copyright (C) 2015 Thomas B. Preusser <thomas.preusser@utexas.edu> " &LF&
    "                   Benedikt Reuter    <breutr@gmail.com>" &LF&
    "This design is free software, and you are welcome to redistribute it " &LF&
    "under the conditions of the GPL version 3. " &LF&
    "It comes with ABSOLUTELY NO WARRANTY. " &LF&
    "For details see the notice in the file COPYING."&LF
    severity note;

    ---------------------------------------------------------------------------
    -- Queen Matrix
    process(clk)
    begin
      if rising_edge(clk) then
        if put = '1' then
          QN(L to N-L-2) <= QN(L+1 to N-L-1);
        else
          QN(L to N-L-2) <= tColumn'(tColumn'range => '-') & QN(L to N-L-3);
        end if;
      end if;

    end process;

    ---------------------------------------------------------------------------
    -- Blocking Signals

    process(clk)
    begin
      if clk'event and clk = '1' then
        -- Initialization
        if start = '1' then
          BH <= BH_l;
          BV <= (BV'left to N-1 => '-') & BV_l;
          BU <= BU_l & (2*N-2*L to BU'right => '-');
          BD <= (BD'left to N-1 => '-') & BD_l;
        else

          -- In Progress
          if put = '1' then
            -- Add placed Queen
            BH <= BH or s;
            BV <= BV(BV'left+1 to BV'right) & '-';
            BU <= '-' & BU(BU'left to N-1) & (BU(N to 2*N-2*L-1) or s) & BU(2*N-2*L to BU'right-1);
            BD <= BD(BD'left+1 to N-1) & (BD(N to 2*N-2*L-1) or s) & BD(2*N-2*L to BD'right) & '-';
          else
            -- Clear Queen
            BH <= BH and not QN(N-L-2);
            BV <= '-' & BV(BV'left to BV'right-1);
            BU <= BU(BU'left+1 to N) & (BU(N+1 to 2*N-2*L) and not QN(N-L-2)) & BU(2*N-2*L+1 to BU'right) & '-';
            BD <= '-' & BD(BD'left to N-2) & (BD(N-1 to 2*N-2*L-2) and not QN(N-L-2)) & BD(2*N-2*L-1 to BD'right-1);
          end if;

        end if;
      end if;

    end process;

    ---------------------------------------------------------------------------
    -- Placement Calculation
    blkPlace : block
      -- State
      signal CS  : std_logic_vector(L to N-L-1) := (others => '0');  -- Column Front Selector
      signal Fwd : std_logic                    := '-';  -- Direction
      signal H   : std_logic_vector(L to N-L-1) := (others => '-');  -- Last Placement in active Col

      -- Combined Blocking
      signal pass : std_logic_vector(L to N-L-1);
      signal tout : std_logic;

      signal st : std_logic_vector(L to N-L-1);
      signal tt : std_logic;

    begin
      -- Combine Blocking Signals
      pass <= BH or BD(N to 2*N-2*L-1) or BU(N to 2*N-2*L-1);

      col : arbit_forward
        generic map (
          N => N-2*L
        )
        port map (
          tin  => Fwd,                  -- Richtung (=put)
          have => H,                    -- FWD-> 000000 ; -FWD-> QN(N-2)
          pass => pass,                 -- BH or BU or BD
          grnt => st,
          tout => tt  -- overflow (q(N)) -> Reihe fertig -> keine dame gesetzt
        );
      tout <= not Fwd         when BV(N) = '1' else tt;
      s    <= (others => '0') when BV(N) = '1' else st;

      QN(N-L-1) <= s;

      -- Column Front Selector, a shift-based counter with:
      process(clk)
      begin
        if clk'event and clk = '1' then
          if rst = '1' then
            CS <= (others => '0');
          elsif start = '1' then
            CS          <= (others => '0');
            CS(CS'left) <= '1';
          else
            if put = '1' then
              CS <= '0' & CS(CS'left to CS'right-1);
            else
              CS <= CS(CS'left+1 to CS'right) & '0';
            end if;
          end if;
        end if;
      end process;

      -- Direction Control
      process(clk)
      begin
        if clk'event and clk = '1' then
          if start = '1' or put = '1' then
            H   <= (others => '0');
            Fwd <= '1';
          else
            H   <= QN(N-L-2);
            Fwd <= '0';
          end if;
        end if;
      end process;

      -- Control
      put <= (not tout) and not CS(CS'right);

      -- Outputs
      process(clk)
      begin
        if clk'event and clk = '1' then
          if rst = '1' or start = '1' then
	    sol  <= '0';
	    done <= '0';
          else
            sol  <= (not tout) and CS(CS'right);
            done <= tout and CS(CS'left);
          end if;
        end if;
      end process;

    end block blkPlace;

end rtl;
