namespace eShop.Ordering.API.Application.DomainEventHandlers;

public class ValidateOrAddBuyerAggregateWhenOrderStartedDomainEventHandler
                    : INotificationHandler<OrderStartedDomainEvent>
{
    private readonly ILogger _logger;
    private readonly IBuyerRepository _buyerRepository;
    private readonly IOrderingIntegrationEventService _orderingIntegrationEventService;

    public ValidateOrAddBuyerAggregateWhenOrderStartedDomainEventHandler(
        ILogger<ValidateOrAddBuyerAggregateWhenOrderStartedDomainEventHandler> logger,
        IBuyerRepository buyerRepository,
        IOrderingIntegrationEventService orderingIntegrationEventService)
    {
        _buyerRepository = buyerRepository ?? throw new ArgumentNullException(nameof(buyerRepository));
        _orderingIntegrationEventService = orderingIntegrationEventService ?? throw new ArgumentNullException(nameof(orderingIntegrationEventService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

   public async Task Handle(OrderStartedDomainEvent domainEvent, CancellationToken cancellationToken)
{
    var cardTypeId = domainEvent.CardTypeId != 0 ? domainEvent.CardTypeId : 1;
    var buyer = await _buyerRepository.FindAsync(domainEvent.UserId);
    var buyerExisted = buyer is not null;

    if (!buyerExisted)
    {
        buyer = new Buyer(domainEvent.UserId, domainEvent.UserName);
    }

    buyer.VerifyOrAddPaymentMethod(cardTypeId,
                                    $"Payment Method on {DateTime.UtcNow}",
                                    domainEvent.CardNumber,
                                    domainEvent.CardSecurityNumber,
                                    domainEvent.CardHolderName,
                                    domainEvent.CardExpiration,
                                    domainEvent.Order.Id);

    if (!buyerExisted)
    {
        _buyerRepository.Add(buyer);
    }

    await _buyerRepository.UnitOfWork
        .SaveEntitiesAsync(cancellationToken);

    // Ensure buyer entity is fully persisted and Id is available after SaveChanges completes
    // Reload buyer to ensure we have the generated Id if it was a new entity
    if (!buyerExisted)
    {
        // Reload buyer to ensure we have the generated Id after SaveChanges
        buyer = await _buyerRepository.FindAsync(domainEvent.UserId);
        if (buyer is null)
        {
            throw new InvalidOperationException($"Buyer with userId {domainEvent.UserId} was not found after creation");
        }
    }

    var integrationEvent = new OrderStatusChangedToSubmittedIntegrationEvent(domainEvent.Order.Id, domainEvent.Order.OrderStatus, buyer.Name, buyer.IdentityGuid);
    await _orderingIntegrationEventService.AddAndSaveEventAsync(integrationEvent);
    OrderingApiTrace.LogOrderBuyerAndPaymentValidatedOrUpdated(_logger, buyer.Id, domainEvent.Order.Id);
}
}
