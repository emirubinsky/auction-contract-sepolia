// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Contrato de Subasta
 * @notice Implementa un sistema de subasta descentralizada con las siguientes características:
 * - Subasta basada en tiempo con extensión dinámica del plazo
 * - Sistema de seguimiento de depósitos y ofertas
 * - Mecanismos de reembolso total y parcial con comisión del 2%
 * - Requisito de incremento mínimo del 5% entre ofertas
 * - Sistema de recuperación de emergencia de ETH
 * @dev Toda la funcionalidad basada en tiempo utiliza block.timestamp
 * @custom:security Diseñado para ser no reentrable, contrato de subasta única
 */
contract Auction {
    struct Bidder {
        uint256 amount;
        address bidder;
    }

    // Variables de estado
    address public owner;
    uint256 public startTime;
    uint256 public stopTime;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 5;
    uint256 public constant REFUND_FEE_PERCENT = 2;

    Bidder public winner;
    Bidder[] public bids;

    // Seguimiento de oferentes
    mapping(address => uint256[]) public userBids;
    mapping(address => uint256) public refundableAmount;
    mapping(address => bool) public hasWithdrawn;

    bool public auctionEnded;

    // Eventos para seguimiento de actividad de la subasta
    event NewOffer(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event PartialRefund(address indexed bidder, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    /**
     * @notice Restringe el acceso de la función solo al propietario del contrato
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownr");
        _;
    }

    /**
     * @notice Asegura que la subasta esté activa y no haya finalizado
     */
    modifier isActive() {
        require(block.timestamp < stopTime, "Inctv");
        require(!auctionEnded, "Ended");
        _;
    }

    /**
     * @notice Asegura que la subasta haya finalizado, sea por tiempo o manualmente
     */
    modifier hasEnded() {
        require(block.timestamp >= stopTime || auctionEnded, "Active");
        _;
    }

    /**
     * @notice Inicializa la subasta con el desplegador como propietario
     * @dev Establece el estado inicial y los parámetros de tiempo
     */
    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        stopTime = startTime + AUCTION_DURATION;
        winner = Bidder(0, address(0));
    }

    /**
     * @notice Realiza una nueva oferta en la subasta
     * @dev Extiende automáticamente la subasta si la oferta se realiza cerca del final
     * Requisitos:
     * - La subasta debe estar activa
     * - La oferta debe ser al menos 5% mayor que la oferta más alta actual
     * - El monto de la oferta se envía a través de msg.value
     * Efectos:
     * - Actualiza el historial de ofertas y el ganador
     * - Puede extender el tiempo de la subasta
     * - Emite evento NewOffer
     */
    function bid() external payable isActive {
        require(msg.value > winner.amount * (100 + MIN_BID_INCREMENT_PERCENT) / 100, "Min incrmnt 5%");

        userBids[msg.sender].push(msg.value);
        refundableAmount[msg.sender] += msg.value;
        bids.push(Bidder(msg.value, msg.sender));

        winner.amount = msg.value;
        winner.bidder = msg.sender;

        if (stopTime - block.timestamp <= EXTENSION_TIME) {
            stopTime += EXTENSION_TIME;
        }

        emit NewOffer(msg.sender, msg.value);
    }

    /**
     * @notice Obtiene la información del ganador actual
     * @return Estructura Bidder conteniendo el monto de la oferta más alta y la dirección del oferente
     */
    function showWinner() external view returns (Bidder memory) {
        return winner;
    }

    /**
     * @notice Obtiene el historial completo de ofertas
     * @return Array de estructuras Bidder conteniendo todas las ofertas
     */
    function showOffers() external view returns (Bidder[] memory) {
        return bids;
    }

    /**
     * @notice Procesa los reembolsos para todos los oferentes no ganadores
     * @dev Solo el propietario puede llamar después de que la subasta termine
     * Requisitos:
     * - Solo el propietario puede llamar
     * - La subasta debe haber terminado
     * - No se puede llamar dos veces
     * Efectos:
     * - Marca la subasta como finalizada
     * - Procesa reembolsos con comisión del 2%
     * - Previene reembolsos duplicados mediante hasWithdrawn
     * - Emite evento AuctionEnded
     */
    function refund() external onlyOwner hasEnded {
        require(!auctionEnded, "Finalized");
        auctionEnded = true;

        uint256 bidsLength = bids.length;
        uint256 i;

        for (i = 0; i < bidsLength; i++) {
            address bidderAddr = bids[i].bidder;
            uint256 totalBid = refundableAmount[bidderAddr];

            if (bidderAddr != winner.bidder && totalBid > 0 && !hasWithdrawn[bidderAddr]) {
                uint256 refundAmount = totalBid * (100 - REFUND_FEE_PERCENT) / 100;
                hasWithdrawn[bidderAddr] = true;
                refundableAmount[bidderAddr] = 0;
                payable(bidderAddr).transfer(refundAmount);
            }
        }

        emit AuctionEnded(winner.bidder, winner.amount);
    }

    /**
     * @notice Permite a los oferentes retirar sus ofertas anteriores durante la subasta
     * @dev Solo reembolsa ofertas anteriores, mantiene la última oferta activa
     * Requisitos:
     * - La subasta debe estar activa
     * - El llamante debe tener al menos 2 ofertas
     * - Debe tener monto reembolsable
     * Efectos:
     * - Reembolsa todas las ofertas excepto la última
     * - Actualiza el monto reembolsable
     * - Emite evento PartialRefund
     */
    function partialRefund() external isActive {
        require(userBids[msg.sender].length > 1, "No prev bids");

        uint256 refundSum = 0;
        uint256 i;

        for (i = 0; i < userBids[msg.sender].length - 1; i++) {
            refundSum += userBids[msg.sender][i];
            userBids[msg.sender][i] = 0;
        }

        require(refundSum > 0, "No refund");
        refundableAmount[msg.sender] -= refundSum;
        payable(msg.sender).transfer(refundSum);

        emit PartialRefund(msg.sender, refundSum);
    }

    /**
     * @notice Función de emergencia para recuperar ETH del contrato
     * @dev Solo el propietario puede llamar
     * Requisitos:
     * - Solo el propietario puede llamar
     * - El contrato debe tener balance
     * Efectos:
     * - Transfiere todo el balance del contrato al propietario
     * - Emite evento EmergencyWithdrawal
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No bal");
        payable(owner).transfer(balance);
        emit EmergencyWithdrawal(owner, balance);
    }
}
