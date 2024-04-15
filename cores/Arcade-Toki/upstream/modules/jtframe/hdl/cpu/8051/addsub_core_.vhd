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
--         Filename:               addsub_core_.vhd
--
--         Date of Creation:       Mon Aug  9 12:14:48 1999
--
--         Version:                $Revision: 1.5 $
--
--         Date of Latest Version: $Date: 2002-01-07 12:17:44 $
--
--
--         Description: Adder/Subtractor with carry/borrow, arbitrary data 
--                      width, overflow, and nibble carry for decimal 
--                      adjustment.
--
--
--
--
-------------------------------------------------------------------------------
library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_arith.all;

library work;
use work.mc8051_p.all;
  
-----------------------------ENTITY DECLARATION--------------------------------

entity addsub_core is
  
  generic (DWIDTH : integer := 16);  	-- Data width of the ALU

  port (opa_i    : in std_logic_vector(DWIDTH-1 downto 0);
        opb_i    : in std_logic_vector(DWIDTH-1 downto 0);
        addsub_i : in std_logic;
        cy_i     : in std_logic;

        cy_o   : out std_logic_vector((DWIDTH-1)/4 downto 0);
        ov_o   : out std_logic;
        rslt_o : out std_logic_vector(DWIDTH-1 downto 0));
 
end addsub_core;

