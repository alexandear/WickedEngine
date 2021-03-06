#include "globals.hlsli"
#include "ShaderInterop_EmittedParticle.h"

RWSTRUCTUREDBUFFER(particleBuffer, Particle, 0);
RWSTRUCTUREDBUFFER(aliveBuffer_OLD, uint, 1);
RWSTRUCTUREDBUFFER(aliveBuffer_NEW, uint, 2);
RWSTRUCTUREDBUFFER(deadBuffer, uint, 3);
RWSTRUCTUREDBUFFER(counterBuffer, uint4, 4);


[numthreads(THREADCOUNT_SIMULATION, 1, 1)]
void main(uint3 DTid : SV_DispatchThreadID)
{
	uint aliveCount = counterBuffer[0][0];

	if (DTid.x < aliveCount)
	{
		uint dt = g_xFrame_DeltaTime * 60.0f;

		uint particleIndex = aliveBuffer_OLD[DTid.x];
		Particle particle = particleBuffer[particleIndex];

		if (particle.life > 0)
		{
			// simulate:
			particle.position += particle.velocity * dt;
			particle.rotation += particle.rotationalVelocity * dt;

			float lifeLerp = 1 - particle.life / particle.maxLife;
			particle.size = lerp(particle.sizeBeginEnd.x, particle.sizeBeginEnd.y, lifeLerp);
			particle.opacity = lerp(1, 0, lifeLerp);

			particle.life -= dt;

			// write back simulated particle:
			particleBuffer[particleIndex] = particle;

			// add to new alive list:
			uint newAliveIndex;
			InterlockedAdd(counterBuffer[0][2], 1, newAliveIndex);
			aliveBuffer_NEW[newAliveIndex] = particleIndex;
		}
		else
		{
			// kill:
			uint deadIndex;
			InterlockedAdd(counterBuffer[0][1], 1, deadIndex);
			deadBuffer[deadIndex] = particleIndex;
		}
	}
}
