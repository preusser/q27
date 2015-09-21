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

entity queens_uart is
  generic (
    -- Problem Size
    N : positive;
    L : positive;

    -- Design Spec
    SOLVERS      : positive;
    COUNT_CYCLES : boolean;

    -- Communication Parameters
    CLK_FREQ : positive;
    BAUDRATE : positive;
    SENTINEL : std_logic_vector(7 downto 0)
  );
  port (
    -- Global Control
    clk : in  std_logic;
    rst : in  std_logic;

    -- UART Interface
    rx : in  std_logic;
    tx : out std_logic;

    -- Activity
    snap  : out std_logic_vector(3 downto 0);
    avail : out std_logic
  );
end queens_uart;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.utils.all;
use PoC.fifo.all;
use PoC.uart.all;

architecture rtl of queens_uart is

  -- Bit Length of Pre-Placement
  constant PRE_BITS  : positive := 4*L*log2ceil(N)-1;
  constant PRE_BYTES : positive := (PRE_BITS+7)/8;

  -- UART-to-Unframe Interface
  signal rx_dat : std_logic_vector(7 downto 0);
  signal rx_stb : std_logic;

  -- Unframe-to-Chain Interface
  signal ivld0 : std_logic;
  signal idat0 : byte;
  signal ieof0 : std_logic;
  signal igot0 : std_logic;

  -- Chain-to-Enframe Interface
  signal ovld0 : std_logic;
  signal odat0 : byte;
  signal oeof0 : std_logic;
  signal ogot0 : std_logic;

  -- Enframe-to-UART Interface
  signal tx_dat : std_logic_vector(7 downto 0);
  signal tx_ful : std_logic;
  signal tx_put : std_logic;

begin

  -----------------------------------------------------------------------------
  -- UART -> Byte Interface
  blkUART: block
    signal bclk_x8 : std_logic;
    signal bclk_x1 : std_logic;
  begin

    -- Bit Clock Generation
    bclk_gen_x8: entity PoC.arith_counter_free
      generic map (
        DIVIDER => CLK_FREQ/(8*BAUDRATE)
      )
      port map (
        clk => clk,
        rst => '0',
        inc => '1',
        stb => bclk_x8
      );
    bclk_gen_x1: entity PoC.arith_counter_free
      generic map (
        DIVIDER => 8
      )
      port map (
        clk => clk,
        rst => '0',
        inc => bclk_x8,
        stb => bclk_x1
      );

    -- Receive Bytes
    uart_rx_2 : uart_rx
      port map (
        clk     => clk,
        rst     => rst,
        bclk_x8 => bclk_x8,
        rx      => rx,
        stb     => rx_stb,
        do      => rx_dat
      );

    -- Transmit Byte
    uart_tx_1 : uart_tx
      port map (
        clk  => clk,
        rst  => rst,
        bclk => bclk_x1,
        put  => tx_put,
        di   => tx_dat,
        ful  => tx_ful,
        tx   => tx
      );

  end block blkUART;

  blkUnframe: block

    -- Input Glue FIFO -> Unframe
    signal glue_vld : std_logic;
    signal glue_dat : std_logic_vector(7 downto 0);
    signal glue_got : std_logic;

    -- Unframe -> Input Buffer
    signal odat : std_logic_vector(7 downto 0);
    signal oeof : std_logic;
    signal oful : std_logic;
    signal oput : std_logic;
    signal ocommit : std_logic;
    signal orollback : std_logic;

  begin

    glue: fifo_glue
      generic map (
        D_BITS => 8
      )
      port map (
        clk => clk,
        rst => rst,
        put => rx_stb,
        di  => rx_dat,
        ful => open,
        vld => glue_vld,
        do  => glue_dat,
        got => glue_got
      );

    unframe_i: entity work.unframe
      generic map (
        SENTINEL => SENTINEL,
        PAY_LEN  => PRE_BYTES
      )
      port map (
        clk       => clk,
        rst       => rst,
        rx_dat    => glue_dat,
        rx_vld    => glue_vld,
        rx_got    => glue_got,
        odat      => odat,
        oeof      => oeof,
        oful      => oful,
        oput      => oput,
        ocommit   => ocommit,
        orollback => orollback
      );

    buf: fifo_cc_got_tempput
      generic map (
        MIN_DEPTH      => 256,
        D_BITS         => 9
      )
      port map (
        clk => clk,
        rst => rst,

        put             => oput,
        din(8)          => oeof,
        din(7 downto 0) => odat,
        full            => oful,
        commit          => ocommit,
        rollback        => orollback,

        got              => igot0,
        dout(8)          => ieof0,
        dout(7 downto 0) => idat0,
        valid            => ivld0
      );

  end block blkUnframe;

  ----------------------------------------------------------------------------
  -- Interface:
  --   - from Unframe: ivld0, idat0, ieof0, igot0
  --   - to   Enframe: ovld0, odat0, oeof0, ogot0
  blkChain: block

    -- Inter-Stage Input Distribution
    signal iful : std_logic_vector(0 to SOLVERS);
    signal iput : std_logic_vector(0 to SOLVERS);
    signal ieof : std_logic_vector(0 to SOLVERS);
    signal idat : byte_vector(0 to SOLVERS);

    -- Inter-Stage Result Stream
    signal ovld : std_logic_vector(0 to SOLVERS-1);
    signal odat : byte_vector(0 to SOLVERS-1);
    signal oeof : std_logic_vector(0 to SOLVERS-1);
    signal ogot : std_logic_vector(0 to SOLVERS-1);

  begin

    -- Feeding Subproblem Chain
    ieof(0) <= ieof0;
    idat(0) <= idat0;
    iput(0) <= ivld0 and not iful(0);
    igot0   <= iput(0);
    iful(SOLVERS) <= '1';    -- Termination

    -- Draining Result Collection Chain
    ovld0 <= ovld(0);
    odat0 <= odat(0);
    oeof0 <= oeof(0);
    ogot(0) <= ogot0;

    -- Actual linear Solver Chain
    genSolvers: for i in 0 to SOLVERS-1 generate

      -- Tap Interface
      signal tful : std_logic;
      signal tput : std_logic;
      signal tdat : std_logic_vector(8*PRE_BYTES-1 downto 0);

      -- Decoded Pre-Placement
      signal bh, bv : std_logic_vector(L to N-L-1);
      signal bu, bd : std_logic_vector(0 to 2*N-4*L-2);

      -- Solver Strobes
      signal sol, done : std_logic;

      -- Computation State
      signal Act : std_logic := '0';
      signal Vld : std_logic := '0';

      -- Result Buffer
      constant BUF_LEN : positive := ite(COUNT_CYCLES, 48, 0) + 8*PRE_BYTES + 52;

      signal Buf : unsigned(BUF_LEN-1 downto 0)                 := (others => '-');
      signal Cnt : unsigned(log2ceil((BUF_LEN+7)/8-1) downto 0) := (others => '-');

      alias Cycles : unsigned(47 downto 0) is Buf(BUF_LEN-1 downto BUF_LEN-48);
      alias Pre    : unsigned(8*PRE_BYTES-1 downto 0) is Buf(8*PRE_BYTES+51 downto 52);
      alias Sols13 : unsigned( 3 downto 0) is Buf(51 downto 48);
      alias Sols15 : unsigned( 3 downto 0) is Buf(47 downto 44);
      alias Sols   : unsigned(43 downto 0) is Buf(43 downto  0);

      -- Streamed Result
      signal rvld : std_logic;
      signal rdat : byte;
      signal reof : std_logic;
      signal rgot : std_logic;

    begin

      -- Input Tap
      tap: entity work.msg_tap
        generic map (
          D => PRE_BYTES
        )
        port map (
          clk  => clk,
          rst  => rst,
          iful => iful(i),
          idat => idat(i),
          ieof => ieof(i),
          iput => iput(i),
          oful => iful(i+1),
          odat => idat(i+1),
          oeof => ieof(i+1),
          oput => iput(i+1),
          tful => tful,
          tdat => tdat,
          tput => tput
        );

      -- Pre-Placement Expansion
      expander: entity work.expand_blocking
        generic map (
          N => N,
          L => L
        )
        port map (
          pre => tdat(PRE_BITS-1 downto 0),
          bh  => bh,
          bv  => bv,
          bu  => bu,
          bd  => bd
        );

      -- Solver Slice
      slice: entity work.queens_slice
        generic map (
          N => N,
          L => L
        )
        port map (
          clk   => clk,
          rst   => rst,
          start => tput,
          BH_l  => bh,
          BU_l  => bu,
          BD_l  => bd,
          BV_l  => bv,
          sol   => sol,
          done  => done
        );

      -- Computation Control
      process(clk)
      begin
        if rising_edge(clk) then
          if rst = '1' then
            Act <= '0';
            Vld <= '0';
            Cnt <= (others => '-');
            Buf <= (others => '-');
          else

            if tput = '1' then
              -- Start
              Act <= '1';
              Buf <= (others => '-');
              if COUNT_CYCLES then
                Cycles <= (others => '0');
              end if;
              Pre    <= unsigned(tdat);
              Sols   <= (others => '0');
              Sols13 <= (others => '0');
              Sols15 <= (others => '0');
            else

              -- Counting Cycles
              if COUNT_CYCLES and Act = '1' and Vld = '0' then
                Cycles <= Cycles + 1;
              end if;

              -- Counting Solutions
              if sol = '1' then
                Sols   <= Sols + 1;
                Sols13 <= Sols13 - ("11" & (1 downto 0 => (not(Sols13(3) and Sols13(2)))));
                Sols15 <= Sols15 - ("111" & (not(Sols15(3) and Sols15(2) and Sols15(1))));
              end if;

              -- Result Output
              if done = '1' then
                Vld <= '1';
                Cnt <= to_unsigned((BUF_LEN+7)/8-2, Cnt'length);
              end if;

              if rgot = '1' then
                Buf <= Buf(Buf'left-8 downto 0) & (1 to 8 => '-');
                Cnt <= Cnt - 1;
                if Cnt(Cnt'left) = '1' then
                  Act <= '0';
                  Vld <= '0';
                end if;
              end if;

            end if;
          end if;
        end if;
      end process;
      tful <= Act;

      rvld <= Vld;
      rdat <= byte(Buf(Buf'left downto Buf'left-7));
      reof <= Cnt(Cnt'left);

      -- Connect Result Stream
      genLast: if i = SOLVERS-1 generate
        ovld(i) <= rvld;
        odat(i) <= rdat;
        oeof(i) <= reof;
        rgot <= ogot(i);
      end generate genLast;
      genFunnel: if i < SOLVERS-1 generate

        -- Funnel-to-FIFO Interface
        signal f2f_ful : std_logic;
        signal f2f_dat : std_logic_vector(8 downto 0);
        signal f2f_put : std_logic;

      begin

        -- Merge local Output with Result Stream
        funnel: entity work.msg_funnel
          generic map (
            N => 2
          )
          port map (
            clk  => clk,
            rst  => rst,

            ivld(0) => rvld,
            ivld(1) => ovld(i+1),
            idat(0) => rdat,
            idat(1) => odat(i+1),
            ieof(0) => reof,
            ieof(1) => oeof(i+1),
            igot(0) => rgot,
            igot(1) => ogot(i+1),

            oful => f2f_ful,
            odat => f2f_dat(7 downto 0),
            oeof => f2f_dat(8),
            oput => f2f_put
          );

        -- Stage Output through FIFO
        genGlue: if 0 < i generate
          glue : fifo_glue
            generic map (
              D_BITS => 9
            )
            port map (
              clk => clk,
              rst => rst,

              ful => f2f_ful,
              di  => f2f_dat,
              put => f2f_put,

              vld            => ovld(i),
              do(7 downto 0) => odat(i),
              do(8)          => oeof(i),
              got            => ogot(i)
            );
        end generate genGlue;
        genBuffer: if i = 0 generate
          fifo_cc_got_1 : fifo_cc_got
            generic map (
              D_BITS     => 9,
              MIN_DEPTH  => (SOLVERS+2*log2ceil(SOLVERS))*((BUF_LEN+7)/8),
              STATE_REG  => true,
              OUTPUT_REG => true
            )
            port map (
              rst => rst,
              clk => clk,

              full => f2f_ful,
              din  => f2f_dat,
              put  => f2f_put,

              valid            => ovld(i),
              dout(7 downto 0) => odat(i),
              dout(8)          => oeof(i),
              got              => ogot(i)
            );
        end generate genBuffer;
      end generate genFunnel;

      genSnap: if i = 0 generate
        snap <= std_logic_vector(Sols15);
      end generate;

    end generate genSolvers;
  end block blkChain;

  blkEnframe: block
  begin
    enframe_i: entity work.enframe
      generic map (
        SENTINEL => SENTINEL
      )
      port map (
        clk    => clk,
        rst    => rst,
        ivld   => ovld0,
        idat   => odat0,
        ieof   => oeof0,
        igot   => ogot0,
        tx_ful => tx_ful,
        tx_put => tx_put,
        tx_dat => tx_dat
      );
  end block blkEnframe;

  avail <= ivld0;

end rtl;
