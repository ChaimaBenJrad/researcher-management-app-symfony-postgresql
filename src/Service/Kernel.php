<?php

namespace App\Service;

use Symfony\Component\DependencyInjection\ContainerInterface;

class ServiceLocator
{
    private $container;

    public function __construct(ContainerInterface $container)
    {
        $this->container = $container;
    }

    public function getPostgresService(): PostgresService
    {
        return $this->container->get(PostgresService::class);
    }
}
