------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Evaldas Juska (evaldas.juska@cern.ch, evka85@gmail.com)
-- 
-- Create Date:    12:22 2016-05-10
-- Module Name:    trigger
-- Description:    This module handles everything related to sbit cluster data (link synchronization, monitoring, local triggering, matching to L1A and reporting data to DAQ)  
------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.gem_pkg.all;
use work.ttc_pkg.all;
use work.ipbus.all;
use work.registers.all;

entity oh_link_regs is
    generic(
        g_NUM_OF_OHs : integer := 1
    );
    port(
        -- reset
        reset_i                 : in  std_logic;
        clk_i                   : in  std_logic;

        -- Link statuses
        gbt_link_status_arr_i   : in t_gbt_link_status_arr(g_NUM_OF_OHs * 3 - 1 downto 0);
        vfat3_link_status_arr_i : in t_oh_vfat_link_status_arr(g_NUM_OF_OHs - 1 downto 0);

        -- IPbus
        ipb_reset_i            : in  std_logic;
        ipb_clk_i              : in  std_logic;
        ipb_miso_o             : out ipb_rbus;
        ipb_mosi_i             : in  ipb_wbus
    );
end oh_link_regs;

architecture oh_link_regs_arch of oh_link_regs is
       
    ------ Register signals begin (this section is generated by <gem_amc_repo_root>/scripts/generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_OH_LINKS_NUM_REGS - 1 downto 0);
    signal regs_write_arr       : t_std32_array(REG_OH_LINKS_NUM_REGS - 1 downto 0);
    signal regs_addresses       : t_std32_array(REG_OH_LINKS_NUM_REGS - 1 downto 0);
    signal regs_defaults        : t_std32_array(REG_OH_LINKS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_OH_LINKS_NUM_REGS - 1 downto 0);
    signal regs_write_pulse_arr : std_logic_vector(REG_OH_LINKS_NUM_REGS - 1 downto 0);
    signal regs_read_ready_arr  : std_logic_vector(REG_OH_LINKS_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_OH_LINKS_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_OH_LINKS_NUM_REGS - 1 downto 0) := (others => '0');
    ------ Register signals end ----------------------------------------------
    
begin
    
    --===============================================================================================
    -- this section is generated by <gem_amc_repo_root>/scripts/generate_registers.py (do not edit) 
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
           g_NUM_REGS             => REG_OH_LINKS_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_OH_LINKS_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_OH_LINKS_ADDRESS_LSB,
           g_USE_INDIVIDUAL_ADDRS => true
       )
       port map(
           ipb_reset_i            => ipb_reset_i,
           ipb_clk_i              => ipb_clk_i,
           ipb_mosi_i             => ipb_mosi_i,
           ipb_miso_o             => ipb_miso_o,
           usr_clk_i              => clk_i,
           regs_read_arr_i        => regs_read_arr,
           regs_write_arr_o       => regs_write_arr,
           read_pulse_arr_o       => regs_read_pulse_arr,
           write_pulse_arr_o      => regs_write_pulse_arr,
           regs_read_ready_arr_i  => regs_read_ready_arr,
           regs_write_done_arr_i  => regs_write_done_arr,
           individual_addrs_arr_i => regs_addresses,
           regs_defaults_arr_i    => regs_defaults,
           writable_regs_i        => regs_writable_arr
      );

    -- Addresses
    regs_addresses(0)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"100";
    regs_addresses(1)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"110";
    regs_addresses(2)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"112";
    regs_addresses(3)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"114";
    regs_addresses(4)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"116";
    regs_addresses(5)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"118";
    regs_addresses(6)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"11a";
    regs_addresses(7)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"11c";
    regs_addresses(8)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"11e";
    regs_addresses(9)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"120";
    regs_addresses(10)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"122";
    regs_addresses(11)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"124";
    regs_addresses(12)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"126";
    regs_addresses(13)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"128";
    regs_addresses(14)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"12a";
    regs_addresses(15)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"12c";
    regs_addresses(16)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"12e";
    regs_addresses(17)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"130";
    regs_addresses(18)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"132";
    regs_addresses(19)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"134";
    regs_addresses(20)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"136";
    regs_addresses(21)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"138";
    regs_addresses(22)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"13a";
    regs_addresses(23)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"13c";
    regs_addresses(24)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"13e";
    regs_addresses(25)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"200";
    regs_addresses(26)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"210";
    regs_addresses(27)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"212";
    regs_addresses(28)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"214";
    regs_addresses(29)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"216";
    regs_addresses(30)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"218";
    regs_addresses(31)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"21a";
    regs_addresses(32)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"21c";
    regs_addresses(33)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"21e";
    regs_addresses(34)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"220";
    regs_addresses(35)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"222";
    regs_addresses(36)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"224";
    regs_addresses(37)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"226";
    regs_addresses(38)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"228";
    regs_addresses(39)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"22a";
    regs_addresses(40)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"22c";
    regs_addresses(41)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"22e";
    regs_addresses(42)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"230";
    regs_addresses(43)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"232";
    regs_addresses(44)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"234";
    regs_addresses(45)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"236";
    regs_addresses(46)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"238";
    regs_addresses(47)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"23a";
    regs_addresses(48)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"23c";
    regs_addresses(49)(REG_OH_LINKS_ADDRESS_MSB downto REG_OH_LINKS_ADDRESS_LSB) <= '0' & x"23e";

    -- Connect read signals
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT0_READY_BIT) <= gbt_link_status_arr_i(0 * 3 + 0).gbt_rx_ready;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT1_READY_BIT) <= gbt_link_status_arr_i(0 * 3 + 1).gbt_rx_ready;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT2_READY_BIT) <= gbt_link_status_arr_i(0 * 3 + 2).gbt_rx_ready;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT0_WAS_NOT_READY_BIT) <= gbt_link_status_arr_i(0 * 3 + 0).gbt_rx_had_not_ready;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT1_WAS_NOT_READY_BIT) <= gbt_link_status_arr_i(0 * 3 + 1).gbt_rx_had_not_ready;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT2_WAS_NOT_READY_BIT) <= gbt_link_status_arr_i(0 * 3 + 2).gbt_rx_had_not_ready;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT0_RX_HAD_OVERFLOW_BIT) <= gbt_link_status_arr_i(0 * 3 + 0).gbt_rx_sync_status.had_ovf;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT1_RX_HAD_OVERFLOW_BIT) <= gbt_link_status_arr_i(0 * 3 + 1).gbt_rx_sync_status.had_ovf;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT2_RX_HAD_OVERFLOW_BIT) <= gbt_link_status_arr_i(0 * 3 + 2).gbt_rx_sync_status.had_ovf;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT0_RX_HAD_UNDERFLOW_BIT) <= gbt_link_status_arr_i(0 * 3 + 0).gbt_rx_sync_status.had_unf;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT1_RX_HAD_UNDERFLOW_BIT) <= gbt_link_status_arr_i(0 * 3 + 1).gbt_rx_sync_status.had_unf;
    regs_read_arr(0)(REG_OH_LINKS_OH0_GBT2_RX_HAD_UNDERFLOW_BIT) <= gbt_link_status_arr_i(0 * 3 + 2).gbt_rx_sync_status.had_unf;
    regs_read_arr(1)(REG_OH_LINKS_OH0_VFAT0_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(0).sync_good;
    regs_read_arr(1)(REG_OH_LINKS_OH0_VFAT0_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT0_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(0).sync_error_cnt;
    regs_read_arr(2)(REG_OH_LINKS_OH0_VFAT1_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(1).sync_good;
    regs_read_arr(2)(REG_OH_LINKS_OH0_VFAT1_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT1_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(1).sync_error_cnt;
    regs_read_arr(3)(REG_OH_LINKS_OH0_VFAT2_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(2).sync_good;
    regs_read_arr(3)(REG_OH_LINKS_OH0_VFAT2_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT2_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(2).sync_error_cnt;
    regs_read_arr(4)(REG_OH_LINKS_OH0_VFAT3_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(3).sync_good;
    regs_read_arr(4)(REG_OH_LINKS_OH0_VFAT3_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT3_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(3).sync_error_cnt;
    regs_read_arr(5)(REG_OH_LINKS_OH0_VFAT4_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(4).sync_good;
    regs_read_arr(5)(REG_OH_LINKS_OH0_VFAT4_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT4_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(4).sync_error_cnt;
    regs_read_arr(6)(REG_OH_LINKS_OH0_VFAT5_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(5).sync_good;
    regs_read_arr(6)(REG_OH_LINKS_OH0_VFAT5_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT5_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(5).sync_error_cnt;
    regs_read_arr(7)(REG_OH_LINKS_OH0_VFAT6_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(6).sync_good;
    regs_read_arr(7)(REG_OH_LINKS_OH0_VFAT6_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT6_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(6).sync_error_cnt;
    regs_read_arr(8)(REG_OH_LINKS_OH0_VFAT7_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(7).sync_good;
    regs_read_arr(8)(REG_OH_LINKS_OH0_VFAT7_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT7_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(7).sync_error_cnt;
    regs_read_arr(9)(REG_OH_LINKS_OH0_VFAT8_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(8).sync_good;
    regs_read_arr(9)(REG_OH_LINKS_OH0_VFAT8_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT8_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(8).sync_error_cnt;
    regs_read_arr(10)(REG_OH_LINKS_OH0_VFAT9_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(9).sync_good;
    regs_read_arr(10)(REG_OH_LINKS_OH0_VFAT9_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT9_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(9).sync_error_cnt;
    regs_read_arr(11)(REG_OH_LINKS_OH0_VFAT10_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(10).sync_good;
    regs_read_arr(11)(REG_OH_LINKS_OH0_VFAT10_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT10_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(10).sync_error_cnt;
    regs_read_arr(12)(REG_OH_LINKS_OH0_VFAT11_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(11).sync_good;
    regs_read_arr(12)(REG_OH_LINKS_OH0_VFAT11_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT11_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(11).sync_error_cnt;
    regs_read_arr(13)(REG_OH_LINKS_OH0_VFAT12_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(12).sync_good;
    regs_read_arr(13)(REG_OH_LINKS_OH0_VFAT12_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT12_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(12).sync_error_cnt;
    regs_read_arr(14)(REG_OH_LINKS_OH0_VFAT13_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(13).sync_good;
    regs_read_arr(14)(REG_OH_LINKS_OH0_VFAT13_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT13_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(13).sync_error_cnt;
    regs_read_arr(15)(REG_OH_LINKS_OH0_VFAT14_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(14).sync_good;
    regs_read_arr(15)(REG_OH_LINKS_OH0_VFAT14_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT14_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(14).sync_error_cnt;
    regs_read_arr(16)(REG_OH_LINKS_OH0_VFAT15_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(15).sync_good;
    regs_read_arr(16)(REG_OH_LINKS_OH0_VFAT15_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT15_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(15).sync_error_cnt;
    regs_read_arr(17)(REG_OH_LINKS_OH0_VFAT16_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(16).sync_good;
    regs_read_arr(17)(REG_OH_LINKS_OH0_VFAT16_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT16_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(16).sync_error_cnt;
    regs_read_arr(18)(REG_OH_LINKS_OH0_VFAT17_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(17).sync_good;
    regs_read_arr(18)(REG_OH_LINKS_OH0_VFAT17_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT17_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(17).sync_error_cnt;
    regs_read_arr(19)(REG_OH_LINKS_OH0_VFAT18_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(18).sync_good;
    regs_read_arr(19)(REG_OH_LINKS_OH0_VFAT18_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT18_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(18).sync_error_cnt;
    regs_read_arr(20)(REG_OH_LINKS_OH0_VFAT19_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(19).sync_good;
    regs_read_arr(20)(REG_OH_LINKS_OH0_VFAT19_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT19_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(19).sync_error_cnt;
    regs_read_arr(21)(REG_OH_LINKS_OH0_VFAT20_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(20).sync_good;
    regs_read_arr(21)(REG_OH_LINKS_OH0_VFAT20_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT20_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(20).sync_error_cnt;
    regs_read_arr(22)(REG_OH_LINKS_OH0_VFAT21_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(21).sync_good;
    regs_read_arr(22)(REG_OH_LINKS_OH0_VFAT21_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT21_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(21).sync_error_cnt;
    regs_read_arr(23)(REG_OH_LINKS_OH0_VFAT22_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(22).sync_good;
    regs_read_arr(23)(REG_OH_LINKS_OH0_VFAT22_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT22_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(22).sync_error_cnt;
    regs_read_arr(24)(REG_OH_LINKS_OH0_VFAT23_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(0)(23).sync_good;
    regs_read_arr(24)(REG_OH_LINKS_OH0_VFAT23_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH0_VFAT23_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(0)(23).sync_error_cnt;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT0_READY_BIT) <= gbt_link_status_arr_i(1 * 3 + 0).gbt_rx_ready;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT1_READY_BIT) <= gbt_link_status_arr_i(1 * 3 + 1).gbt_rx_ready;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT2_READY_BIT) <= gbt_link_status_arr_i(1 * 3 + 2).gbt_rx_ready;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT0_WAS_NOT_READY_BIT) <= gbt_link_status_arr_i(1 * 3 + 0).gbt_rx_had_not_ready;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT1_WAS_NOT_READY_BIT) <= gbt_link_status_arr_i(1 * 3 + 1).gbt_rx_had_not_ready;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT2_WAS_NOT_READY_BIT) <= gbt_link_status_arr_i(1 * 3 + 2).gbt_rx_had_not_ready;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT0_RX_HAD_OVERFLOW_BIT) <= gbt_link_status_arr_i(1 * 3 + 0).gbt_rx_sync_status.had_ovf;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT1_RX_HAD_OVERFLOW_BIT) <= gbt_link_status_arr_i(1 * 3 + 1).gbt_rx_sync_status.had_ovf;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT2_RX_HAD_OVERFLOW_BIT) <= gbt_link_status_arr_i(1 * 3 + 2).gbt_rx_sync_status.had_ovf;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT0_RX_HAD_UNDERFLOW_BIT) <= gbt_link_status_arr_i(1 * 3 + 0).gbt_rx_sync_status.had_unf;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT1_RX_HAD_UNDERFLOW_BIT) <= gbt_link_status_arr_i(1 * 3 + 1).gbt_rx_sync_status.had_unf;
    regs_read_arr(25)(REG_OH_LINKS_OH1_GBT2_RX_HAD_UNDERFLOW_BIT) <= gbt_link_status_arr_i(1 * 3 + 2).gbt_rx_sync_status.had_unf;
    regs_read_arr(26)(REG_OH_LINKS_OH1_VFAT0_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(0).sync_good;
    regs_read_arr(26)(REG_OH_LINKS_OH1_VFAT0_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT0_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(0).sync_error_cnt;
    regs_read_arr(27)(REG_OH_LINKS_OH1_VFAT1_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(1).sync_good;
    regs_read_arr(27)(REG_OH_LINKS_OH1_VFAT1_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT1_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(1).sync_error_cnt;
    regs_read_arr(28)(REG_OH_LINKS_OH1_VFAT2_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(2).sync_good;
    regs_read_arr(28)(REG_OH_LINKS_OH1_VFAT2_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT2_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(2).sync_error_cnt;
    regs_read_arr(29)(REG_OH_LINKS_OH1_VFAT3_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(3).sync_good;
    regs_read_arr(29)(REG_OH_LINKS_OH1_VFAT3_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT3_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(3).sync_error_cnt;
    regs_read_arr(30)(REG_OH_LINKS_OH1_VFAT4_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(4).sync_good;
    regs_read_arr(30)(REG_OH_LINKS_OH1_VFAT4_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT4_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(4).sync_error_cnt;
    regs_read_arr(31)(REG_OH_LINKS_OH1_VFAT5_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(5).sync_good;
    regs_read_arr(31)(REG_OH_LINKS_OH1_VFAT5_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT5_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(5).sync_error_cnt;
    regs_read_arr(32)(REG_OH_LINKS_OH1_VFAT6_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(6).sync_good;
    regs_read_arr(32)(REG_OH_LINKS_OH1_VFAT6_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT6_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(6).sync_error_cnt;
    regs_read_arr(33)(REG_OH_LINKS_OH1_VFAT7_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(7).sync_good;
    regs_read_arr(33)(REG_OH_LINKS_OH1_VFAT7_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT7_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(7).sync_error_cnt;
    regs_read_arr(34)(REG_OH_LINKS_OH1_VFAT8_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(8).sync_good;
    regs_read_arr(34)(REG_OH_LINKS_OH1_VFAT8_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT8_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(8).sync_error_cnt;
    regs_read_arr(35)(REG_OH_LINKS_OH1_VFAT9_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(9).sync_good;
    regs_read_arr(35)(REG_OH_LINKS_OH1_VFAT9_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT9_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(9).sync_error_cnt;
    regs_read_arr(36)(REG_OH_LINKS_OH1_VFAT10_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(10).sync_good;
    regs_read_arr(36)(REG_OH_LINKS_OH1_VFAT10_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT10_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(10).sync_error_cnt;
    regs_read_arr(37)(REG_OH_LINKS_OH1_VFAT11_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(11).sync_good;
    regs_read_arr(37)(REG_OH_LINKS_OH1_VFAT11_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT11_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(11).sync_error_cnt;
    regs_read_arr(38)(REG_OH_LINKS_OH1_VFAT12_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(12).sync_good;
    regs_read_arr(38)(REG_OH_LINKS_OH1_VFAT12_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT12_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(12).sync_error_cnt;
    regs_read_arr(39)(REG_OH_LINKS_OH1_VFAT13_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(13).sync_good;
    regs_read_arr(39)(REG_OH_LINKS_OH1_VFAT13_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT13_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(13).sync_error_cnt;
    regs_read_arr(40)(REG_OH_LINKS_OH1_VFAT14_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(14).sync_good;
    regs_read_arr(40)(REG_OH_LINKS_OH1_VFAT14_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT14_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(14).sync_error_cnt;
    regs_read_arr(41)(REG_OH_LINKS_OH1_VFAT15_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(15).sync_good;
    regs_read_arr(41)(REG_OH_LINKS_OH1_VFAT15_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT15_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(15).sync_error_cnt;
    regs_read_arr(42)(REG_OH_LINKS_OH1_VFAT16_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(16).sync_good;
    regs_read_arr(42)(REG_OH_LINKS_OH1_VFAT16_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT16_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(16).sync_error_cnt;
    regs_read_arr(43)(REG_OH_LINKS_OH1_VFAT17_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(17).sync_good;
    regs_read_arr(43)(REG_OH_LINKS_OH1_VFAT17_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT17_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(17).sync_error_cnt;
    regs_read_arr(44)(REG_OH_LINKS_OH1_VFAT18_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(18).sync_good;
    regs_read_arr(44)(REG_OH_LINKS_OH1_VFAT18_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT18_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(18).sync_error_cnt;
    regs_read_arr(45)(REG_OH_LINKS_OH1_VFAT19_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(19).sync_good;
    regs_read_arr(45)(REG_OH_LINKS_OH1_VFAT19_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT19_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(19).sync_error_cnt;
    regs_read_arr(46)(REG_OH_LINKS_OH1_VFAT20_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(20).sync_good;
    regs_read_arr(46)(REG_OH_LINKS_OH1_VFAT20_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT20_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(20).sync_error_cnt;
    regs_read_arr(47)(REG_OH_LINKS_OH1_VFAT21_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(21).sync_good;
    regs_read_arr(47)(REG_OH_LINKS_OH1_VFAT21_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT21_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(21).sync_error_cnt;
    regs_read_arr(48)(REG_OH_LINKS_OH1_VFAT22_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(22).sync_good;
    regs_read_arr(48)(REG_OH_LINKS_OH1_VFAT22_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT22_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(22).sync_error_cnt;
    regs_read_arr(49)(REG_OH_LINKS_OH1_VFAT23_LINK_GOOD_BIT) <= vfat3_link_status_arr_i(1)(23).sync_good;
    regs_read_arr(49)(REG_OH_LINKS_OH1_VFAT23_SYNC_ERR_CNT_MSB downto REG_OH_LINKS_OH1_VFAT23_SYNC_ERR_CNT_LSB) <= vfat3_link_status_arr_i(1)(23).sync_error_cnt;

    -- Connect write signals

    -- Connect write pulse signals

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect read ready signals

    -- Defaults

    -- Define writable regs

    --==== Registers end ============================================================================
    
end oh_link_regs_arch;

