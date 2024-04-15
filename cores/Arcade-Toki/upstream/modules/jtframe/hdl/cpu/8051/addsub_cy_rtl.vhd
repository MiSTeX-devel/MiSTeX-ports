-------------------------------------------------------------------------------
--                                                                           --
--          X       X   XXXXXX    XXXXXX    XXXXXX    XXXXXX      X          --
--          XX     XX  X      X  X      X  X      X  X           XX          --
--          X X   X X  X         X      X  X      X  X          X X          --
--          X  X X  X  X         X      X  X      X  X         X  X          --
--          X   X   X  X          XXXXXX   X      X   XXXXXX      X          --
--          X       X  X         X      X  X      X         X     X          --
--          X       X  X         X      X  X      X         X     X          --
--          X       X  X      X  X      X  X      X         X     X          --
--          X       X   XXXXXX    XXXXXX    XXXXXX    XXXXXX      X          --
--                                                                           --
--                                                                           --
--                       O R E G A N O   S Y S T E M S                       --
--                                                                           --
--                            Design & Consulting                            --
--                                                                           --
-------------------------------------------------------------------------------
--                                                                           --
--         Web:           http://www.oregano.at/                             --
--                                                                           --
--         Contact:       mc8051@oregano.at                                  --
--                                                                           --
-------------------------------------------------------------------------------
--                                                                           --
--  MC8051 - VHDL 8051 Microcontroller IP Core                               --
--  Copyright (C) 2001 OREGANO SYSTEMS                                       --
--                                                                           --
--  This library is free software; you can redistribute it and/or            --
--  modify it under the terms of the GNU Lesser General Public               --
--  License as published by the Free Software Foundation; either             --
--  version 2.1 of the License, or (at your option) any later version.       --
--                                                                           --
--  This library is distributed in the hope that it will be useful,          --
--  but WITHOUT ANY WARRANTY; without even the implied warranty of           --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        --
--  Lesser General Public License for more details.                          --
--                                                                           --
--  Full details of the license can be found in the file LGPL.TXT.           --
--                                                                           --
--  You should have received a copy of the GNU Lesser General Public         --
--  License along with this library; if not, write to the Free Software      --
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA  --
--                                                                           --
-------------------------------------------------------------------------------
--
--
--         Author:                 Roland H�ller
--
--         Filename:               addsub_cy_rtl.vhd
--
--         Date of Creation:       Mon Aug  9 12:14:48 1999
--
--         Version:                $Revision: 1.4 $
--
--         Date of Latest Version: $Date: 2002-01-07 12:17:44 $
--
--
--         Description: Adder/Subtractor with carry/borrow and arbitrary
--                      data width.
--
--
--
--
-------------------------------------------------------------------------------
architecture rtl of addsub_cy is

begin

  -- purpose: Simple adder/subtractor with carry/borrow
  -- type   : combinational
  -- inputs : opa_i, opb_i, addsub_i
  -- outputs: cy_o, rslt_o
  p_addsub: process (opa_i, opb_i, addsub_i, cy_i)
    variable v_a : unsigned(DWIDTH downto 0);
    variable v_b : unsigned(DWIDTH downto 0);
    variable v_result : std_logic_vector(DWIDTH+1 downto 0);
  begin  -- process p_addsub
    v_a(DWIDTH downto 1) := unsigned(opa_i);
    v_b(DWIDTH downto 1) := unsigned(opb_i);
    if addsub_i = '1' then
      v_a(0) := '1';
      v_b(0) := cy_i;
      v_result := conv_unsigned(v_a,DWIDTH+2) + v_b;
    else
      v_a(0) := '0';
      v_b(0) := cy_i;
      v_result := conv_unsigned(v_a,DWIDTH+2) - v_b;
    end if;
    cy_o <= v_result(DWIDTH+1);
    rslt_o <= v_result(DWIDTH downto 1);
  end process p_addsub;

end rtl;
