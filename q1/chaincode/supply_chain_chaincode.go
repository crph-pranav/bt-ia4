package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SupplyChainContract provides functions for managing supply chain
type SupplyChainContract struct {
	contractapi.Contract
}

// Product represents a product in the supply chain
type Product struct {
	ProductID       string          `json:"productID"`
	Name            string          `json:"name"`
	Description     string          `json:"description"`
	Manufacturer    string          `json:"manufacturer"`
	ManufactureDate string          `json:"manufactureDate"`
	CurrentOwner    string          `json:"currentOwner"`
	CurrentLocation string          `json:"currentLocation"`
	Status          string          `json:"status"` // CREATED, IN_TRANSIT, DELIVERED
	History         []ShipmentEvent `json:"history"`
}

// ShipmentEvent represents an event in the product lifecycle
type ShipmentEvent struct {
	EventType   string `json:"eventType"`   // CREATED, TRANSFERRED, RECEIVED
	From        string `json:"from"`
	To          string `json:"to"`
	Location    string `json:"location"`
	Timestamp   string `json:"timestamp"`
	Handler     string `json:"handler"`
	Description string `json:"description"`
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	Key    string `json:"Key"`
	Record *Product
}

// InitLedger adds a base set of products to the ledger
func (s *SupplyChainContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	products := []Product{
		{
			ProductID:       "PROD001",
			Name:            "Sample Product",
			Description:     "Initial product for testing",
			Manufacturer:    "ManufacturerMSP",
			ManufactureDate: time.Now().Format(time.RFC3339),
			CurrentOwner:    "ManufacturerMSP",
			CurrentLocation: "Manufacturing Facility",
			Status:          "CREATED",
			History:         []ShipmentEvent{},
		},
	}

	for _, product := range products {
		productJSON, err := json.Marshal(product)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(product.ProductID, productJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state: %v", err)
		}
	}

	return nil
}

// CreateProduct creates a new product in the supply chain
func (s *SupplyChainContract) CreateProduct(ctx contractapi.TransactionContextInterface, 
	productID string, name string, description string) (*Product, error) {
	
	// Get caller's identity
	callerMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return nil, fmt.Errorf("failed to get caller MSPID: %v", err)
	}

	// Only manufacturer can create products
	if callerMSPID != "ManufacturerMSP" {
		return nil, fmt.Errorf("only manufacturer can create products")
	}

	// Check if product already exists
	exists, err := s.ProductExists(ctx, productID)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, fmt.Errorf("the product %s already exists", productID)
	}

	// Create initial event
	initialEvent := ShipmentEvent{
		EventType:   "CREATED",
		From:        "",
		To:          callerMSPID,
		Location:    "Manufacturing Facility",
		Timestamp:   time.Now().Format(time.RFC3339),
		Handler:     callerMSPID,
		Description: "Product created by manufacturer",
	}

	product := Product{
		ProductID:       productID,
		Name:            name,
		Description:     description,
		Manufacturer:    callerMSPID,
		ManufactureDate: time.Now().Format(time.RFC3339),
		CurrentOwner:    callerMSPID,
		CurrentLocation: "Manufacturing Facility",
		Status:          "CREATED",
		History:         []ShipmentEvent{initialEvent},
	}

	productJSON, err := json.Marshal(product)
	if err != nil {
		return nil, err
	}

	err = ctx.GetStub().PutState(productID, productJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to put product to world state: %v", err)
	}

	return &product, nil
}

// TransferShipment transfers a product from one organization to another
func (s *SupplyChainContract) TransferShipment(ctx contractapi.TransactionContextInterface, 
	productID string, toOrg string, location string) (*Product, error) {
	
	// Get caller's identity
	callerMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return nil, fmt.Errorf("failed to get caller MSPID: %v", err)
	}

	// Read current product state
	productJSON, err := ctx.GetStub().GetState(productID)
	if err != nil {
		return nil, fmt.Errorf("failed to read product: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("the product %s does not exist", productID)
	}

	var product Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, err
	}

	// Only current owner can transfer
	if product.CurrentOwner != callerMSPID {
		return nil, fmt.Errorf("only current owner can transfer the product")
	}

	// Validate transfer path
	validTransfer := false
	if (callerMSPID == "ManufacturerMSP" && toOrg == "DistributorMSP") ||
	   (callerMSPID == "DistributorMSP" && toOrg == "RetailerMSP") {
		validTransfer = true
	}

	if !validTransfer {
		return nil, fmt.Errorf("invalid transfer path from %s to %s", callerMSPID, toOrg)
	}

	// Create transfer event
	transferEvent := ShipmentEvent{
		EventType:   "TRANSFERRED",
		From:        product.CurrentOwner,
		To:          toOrg,
		Location:    location,
		Timestamp:   time.Now().Format(time.RFC3339),
		Handler:     callerMSPID,
		Description: fmt.Sprintf("Product transferred from %s to %s", product.CurrentOwner, toOrg),
	}

	// Update product
	product.CurrentOwner = toOrg
	product.CurrentLocation = location
	product.Status = "IN_TRANSIT"
	product.History = append(product.History, transferEvent)

	productJSON, err = json.Marshal(product)
	if err != nil {
		return nil, err
	}

	err = ctx.GetStub().PutState(productID, productJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to update product: %v", err)
	}

	return &product, nil
}

// ReceiveShipment marks a product as received
func (s *SupplyChainContract) ReceiveShipment(ctx contractapi.TransactionContextInterface, 
	productID string, location string) (*Product, error) {
	
	// Get caller's identity
	callerMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return nil, fmt.Errorf("failed to get caller MSPID: %v", err)
	}

	// Read current product state
	productJSON, err := ctx.GetStub().GetState(productID)
	if err != nil {
		return nil, fmt.Errorf("failed to read product: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("the product %s does not exist", productID)
	}

	var product Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, err
	}

	// Only current owner can receive
	if product.CurrentOwner != callerMSPID {
		return nil, fmt.Errorf("only current owner can receive the product")
	}

	// Create receive event
	receiveEvent := ShipmentEvent{
		EventType:   "RECEIVED",
		From:        product.CurrentOwner,
		To:          product.CurrentOwner,
		Location:    location,
		Timestamp:   time.Now().Format(time.RFC3339),
		Handler:     callerMSPID,
		Description: fmt.Sprintf("Product received by %s", callerMSPID),
	}

	// Update product
	product.CurrentLocation = location
	product.Status = "DELIVERED"
	product.History = append(product.History, receiveEvent)

	productJSON, err = json.Marshal(product)
	if err != nil {
		return nil, err
	}

	err = ctx.GetStub().PutState(productID, productJSON)
	if err != nil {
		return nil, fmt.Errorf("failed to update product: %v", err)
	}

	return &product, nil
}

// QueryProduct returns the product stored in the world state with given id
func (s *SupplyChainContract) QueryProduct(ctx contractapi.TransactionContextInterface, 
	productID string) (*Product, error) {
	
	productJSON, err := ctx.GetStub().GetState(productID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if productJSON == nil {
		return nil, fmt.Errorf("the product %s does not exist", productID)
	}

	var product Product
	err = json.Unmarshal(productJSON, &product)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

// QueryProductHistory returns the history of a product
func (s *SupplyChainContract) QueryProductHistory(ctx contractapi.TransactionContextInterface, 
	productID string) ([]ShipmentEvent, error) {
	
	product, err := s.QueryProduct(ctx, productID)
	if err != nil {
		return nil, err
	}

	return product.History, nil
}

// GetAllProducts returns all products found in world state
func (s *SupplyChainContract) GetAllProducts(ctx contractapi.TransactionContextInterface) ([]*Product, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var products []*Product
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product Product
		err = json.Unmarshal(queryResponse.Value, &product)
		if err != nil {
			return nil, err
		}
		products = append(products, &product)
	}

	return products, nil
}

// ProductExists returns true when product with given ID exists in world state
func (s *SupplyChainContract) ProductExists(ctx contractapi.TransactionContextInterface, 
	productID string) (bool, error) {
	
	productJSON, err := ctx.GetStub().GetState(productID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return productJSON != nil, nil
}

// GetProductsByOwner returns all products owned by a specific organization
func (s *SupplyChainContract) GetProductsByOwner(ctx contractapi.TransactionContextInterface, 
	owner string) ([]*Product, error) {
	
	queryString := fmt.Sprintf(`{"selector":{"currentOwner":"%s"}}`, owner)
	
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var products []*Product
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product Product
		err = json.Unmarshal(queryResponse.Value, &product)
		if err != nil {
			return nil, err
		}
		products = append(products, &product)
	}

	return products, nil
}

// GetProductHistory returns the transaction history for a product
func (s *SupplyChainContract) GetProductHistory(ctx contractapi.TransactionContextInterface, 
	productID string) ([]QueryResult, error) {
	
	resultsIterator, err := ctx.GetStub().GetHistoryForKey(productID)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []QueryResult
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var product Product
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &product)
			if err != nil {
				return nil, err
			}
		}

		record := QueryResult{
			Key:    response.TxId,
			Record: &product,
		}
		records = append(records, record)
	}

	return records, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SupplyChainContract{})
	if err != nil {
		fmt.Printf("Error creating supply chain chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting supply chain chaincode: %v\n", err)
	}
}